import Foundation
import SkiPassMail
import SkiPassModels
import SkiPassStorage

/// Resolves the IMAP secret for a mailbox from the Keychain, refreshing OAuth tokens as needed
/// and writing the updated auth state back. Usable from the AutoFill extension; pass it directly
/// to `IMAPMailFetcher(credentials:timeout:)`.
public struct OAuthCredentialProvider: CredentialProviding {
    private let store: CredentialStore
    private let service: OAuthService

    public init(store: CredentialStore = CredentialStore(), service: OAuthService = OAuthService()) {
        self.store = store
        self.service = service
    }

    public func credential(for mailbox: MailboxConfig) async throws -> MailCredential {
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
