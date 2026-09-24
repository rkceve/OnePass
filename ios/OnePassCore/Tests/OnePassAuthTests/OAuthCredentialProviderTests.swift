import Foundation
import OnePassAuth
import OnePassMail
import OnePassModels
import OnePassStorage
import XCTest

/// In-memory stand-in for the Keychain (SPM test bundles have no keychain-access-group entitlement).
private final class InMemorySecrets: SecretStoring, @unchecked Sendable {
    // @unchecked: every access to `items` is serialized by `lock`.
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    func setData(_ data: Data, account: String) throws {
        lock.lock(); defer { lock.unlock() }
        items[account] = data
    }

    func data(account: String) throws -> Data? {
        lock.lock(); defer { lock.unlock() }
        return items[account]
    }

    func delete(account: String) throws {
        lock.lock(); defer { lock.unlock() }
        items[account] = nil
    }
}

final class OAuthCredentialProviderTests: XCTestCase {
    private let clients = OAuthClientConfiguration(googleClientID: nil, microsoftClientID: nil)

    private func mailbox(_ kind: ProviderKind) -> MailboxConfig {
        MailboxConfig(address: "user@example.com", kind: kind, imapHost: "imap.example.com",
                      imapPort: 993, username: "user@example.com")
    }

    private func provider(_ store: CredentialStore) -> any CredentialProviding {
        OAuthCredentialProvider(store: store, service: OAuthService(clients: clients))
    }

    func testIMAPMailboxUsesStoredPassword() async throws {
        let store = CredentialStore(secrets: InMemorySecrets())
        let box = mailbox(.imap)
        try store.setIMAPPassword("app-specific-password", for: box.id)

        let credential = try await provider(store).credential(for: box)

        XCTAssertEqual(credential, .password("app-specific-password"))
    }

    func testIMAPMailboxWithoutPasswordThrows() async {
        let box = mailbox(.imap)
        do {
            _ = try await provider(CredentialStore(secrets: InMemorySecrets())).credential(for: box)
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? OAuthError, .missingStoredSecret(mailboxID: box.id))
        }
    }

    func testOAuthMailboxWithoutStoredStateThrows() async {
        for kind in [ProviderKind.google, .microsoft] {
            let box = mailbox(kind)
            do {
                _ = try await provider(CredentialStore(secrets: InMemorySecrets())).credential(for: box)
                XCTFail("expected an error for \(kind)")
            } catch {
                XCTAssertEqual(error as? OAuthError, .missingStoredSecret(mailboxID: box.id))
            }
        }
    }

    func testOAuthMailboxWithCorruptStateThrowsAndKeepsStoredData() async throws {
        let store = CredentialStore(secrets: InMemorySecrets())
        let box = mailbox(.google)
        let garbage = Data("not an archived OIDAuthState".utf8)
        try store.setOAuthStateData(garbage, for: box.id)

        do {
            _ = try await provider(store).credential(for: box)
            XCTFail("expected an error")
        } catch {
            // Either NSKeyedUnarchiver's decoding error or OAuthError.invalidAuthState.
        }
        XCTAssertEqual(try store.oauthStateData(for: box.id), garbage)
    }
}
