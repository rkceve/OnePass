import Foundation
import OnePassModels
import OnePassStorage

/// Resolves the IMAP secret for a mailbox from the Keychain, refreshing OAuth tokens as needed
/// and writing the updated auth state back. Usable from the AutoFill extension.
///
/// OPEN(package): `CredentialProviding` / `MailCredential` live in OnePassMail, which OnePassAuth
/// does not depend on in the fixed Package.swift, so this type cannot declare the conformance
/// yet. Until the dependency is added, wire it with OnePassMail's `ClosureCredentialProvider`:
///
///     ClosureCredentialProvider { mailbox in
///         switch try await provider.resolve(for: mailbox) {
///         case .password(let p): return .password(p)
///         case .xoauth2(let t): return .xoauth2(accessToken: t)
///         }
///     }
public struct OAuthCredentialProvider: Sendable {
    public enum Resolved: Sendable, Equatable {
        case password(String)
        case xoauth2(accessToken: String)
    }

    private let store: CredentialStore
    private let service: OAuthService

    public init(store: CredentialStore = CredentialStore(), service: OAuthService = OAuthService()) {
        self.store = store
        self.service = service
    }

    public func resolve(for mailbox: MailboxConfig) async throws -> Resolved {
        switch mailbox.kind {
        case .imap:
            guard let password = try store.imapPassword(for: mailbox.id) else {
                throw OAuthError.missingStoredSecret(mailboxID: mailbox.id)
            }
            return .password(password)
        case .google, .microsoft:
            guard let stateData = try store.oauthStateData(for: mailbox.id) else {
                throw OAuthError.missingStoredSecret(mailboxID: mailbox.id)
            }
            let fresh = try await service.freshAccessToken(authStateData: stateData)
            if fresh.updatedStateData != stateData {
                try store.setOAuthStateData(fresh.updatedStateData, for: mailbox.id)
            }
            return .xoauth2(accessToken: fresh.token)
        }
    }
}
