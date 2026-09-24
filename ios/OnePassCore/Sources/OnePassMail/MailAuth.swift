import Foundation
import OnePassModels

/// What `IMAPMailFetcher` uses to authenticate one IMAP session.
public enum MailCredential: Sendable, Equatable {
    /// IMAP `LOGIN` with the mailbox username and this (app-specific) password.
    case password(String)
    /// SASL `XOAUTH2` with the mailbox username and a fresh OAuth access token.
    case xoauth2(accessToken: String)
}

public protocol CredentialProviding: Sendable {
    func credential(for mailbox: MailboxConfig) async throws -> MailCredential
}

/// Adapter so callers can wire any async source (e.g. OnePassAuth's `OAuthCredentialProvider`)
/// without OnePassMail depending on it.
public struct ClosureCredentialProvider: CredentialProviding {
    private let body: @Sendable (MailboxConfig) async throws -> MailCredential

    public init(_ body: @escaping @Sendable (MailboxConfig) async throws -> MailCredential) {
        self.body = body
    }

    public func credential(for mailbox: MailboxConfig) async throws -> MailCredential {
        try await body(mailbox)
    }
}
