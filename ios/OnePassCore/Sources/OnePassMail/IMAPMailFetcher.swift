import Foundation
import OnePassModels
import SwiftMail

/// Reads recent INBOX messages over IMAP (SwiftMail 1.12.0) without changing mailbox state.
///
/// Read-only guarantees:
/// - INBOX is opened with EXAMINE (`IMAPServer.examineMailbox`), so the server rejects STORE and
///   does not set `\Seen` (RFC 3501 §6.3.2).
/// - Every SwiftMail body/header fetch uses `BODY.PEEK` (FetchCommands.swift L75, L78, L155).
public struct IMAPMailFetcher: MailFetching {
    private let credentials: any CredentialProviding
    private let timeout: TimeInterval
    private let maxMessages: Int

    /// - Parameters:
    ///   - credentials: Supplies the password or OAuth access token per mailbox.
    ///   - timeout: Wall-clock budget in seconds for one `recentMessages` call (credential lookup,
    ///     connect, login, search, fetch). On expiry the connection is dropped and
    ///     `MailFetchError.timedOut` is thrown.
    ///   - maxMessages: Upper bound on messages examined per call (newest UIDs first).
    public init(credentials: any CredentialProviding, timeout: TimeInterval, maxMessages: Int = 50) {
        self.credentials = credentials
        self.timeout = timeout
        self.maxMessages = maxMessages
    }

    public func recentMessages(for mailbox: MailboxConfig, since: Date) async throws -> [FetchedMessage] {
        let server = IMAPServer(
            host: mailbox.imapHost,
            port: mailbox.imapPort,
            // 993 is IMAP over implicit TLS; any other port must upgrade with STARTTLS. Never plaintext.
            transportSecurity: mailbox.imapPort == 993 ? .implicitTLS : .startTLS
        )
        let credentials = self.credentials
        let maxMessages = self.maxMessages
        return try await Deadline.run(
            seconds: timeout,
            operation: {
                try await Self.fetch(server: server, mailbox: mailbox, since: since,
                                     credentials: credentials, maxMessages: maxMessages)
            },
            onTimeout: { try? await server.disconnect() }
        )
    }

    private static func fetch(server: IMAPServer, mailbox: MailboxConfig, since: Date,
                              credentials: any CredentialProviding, maxMessages: Int) async throws -> [FetchedMessage] {
        do {
            let credential = try await credentials.credential(for: mailbox)
            try await server.connect()
            switch credential {
            case .password(let password):
                try await server.login(username: mailbox.username, password: password)
            case .xoauth2(let accessToken):
                try await server.authenticateXOAUTH2(email: mailbox.username, accessToken: accessToken)
            }
            try await server.examineMailbox("INBOX")

            let found: [UID] = try await server.search(
                criteria: [.since(FetchLogic.searchDay(for: since))],
                sortCriteria: [],
                calendar: FetchLogic.searchCalendar
            )
            let uids = FetchLogic.newestUIDs(found, limit: maxMessages)
            var messages: [FetchedMessage] = []
            if !uids.isEmpty {
                let infos = try await server.fetchMessageInfosBulk(
                    using: MessageIdentifierSet<UID>(uids),
                    options: [.envelope, .internalDate, .bodyStructure]
                )
                for info in infos where FetchLogic.isRecent(info, since: since) {
                    guard let uid = info.uid else { continue }
                    let body = try await bodyText(server: server, info: info, uid: uid)
                    messages.append(FetchLogic.makeMessage(info: info, uid: uid, mailbox: mailbox, bodyText: body))
                }
            }
            try? await server.logout()
            return messages
        } catch {
            try? await server.disconnect()
            throw error
        }
    }

    /// text/plain if present and non-empty, else text/html converted to text, else "".
    private static func bodyText(server: IMAPServer, info: MessageInfo, uid: UID) async throws -> String {
        for candidate in FetchLogic.bodyCandidates(for: info) {
            let raw = try await server.fetchPart(section: candidate.part.section, of: uid)
            if let text = FetchLogic.text(of: candidate.part, rawData: raw, kind: candidate.kind),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }
        return ""
    }
}
