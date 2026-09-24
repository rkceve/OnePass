import Foundation
import OnePassAuth
import OnePassModels
import XCTest

// `OAuthProviderSettings` is `package`-visible, so this test target (same package) can use it
// without `@testable`.

final class GoogleRedirectURLTests: XCTestCase {
    func testRedirectUsesReversedClientIDScheme() throws {
        let url = try OAuthProviderSettings.googleRedirectURL(
            clientID: "123456789012-abcdefghijklmnop.apps.googleusercontent.com")
        // CONTRACTS §2: com.googleusercontent.apps.<GOOGLE_CLIENT_ID_PREFIX>:/oauth2redirect
        XCTAssertEqual(url.absoluteString,
                       "com.googleusercontent.apps.123456789012-abcdefghijklmnop:/oauth2redirect")
        XCTAssertEqual(url.scheme, "com.googleusercontent.apps.123456789012-abcdefghijklmnop")
    }

    func testRejectsClientIDWithoutGoogleSuffix() {
        XCTAssertThrowsError(try OAuthProviderSettings.googleRedirectURL(clientID: "123456789012-abc")) {
            XCTAssertEqual($0 as? OAuthError, .invalidGoogleClientID)
        }
    }

    func testRejectsBareSuffix() {
        XCTAssertThrowsError(try OAuthProviderSettings.googleRedirectURL(clientID: ".apps.googleusercontent.com")) {
            XCTAssertEqual($0 as? OAuthError, .invalidGoogleClientID)
        }
    }
}

final class ProviderSettingsTests: XCTestCase {
    private let clients = OAuthClientConfiguration(
        googleClientID: "123456789012-abcdefghijklmnop.apps.googleusercontent.com",
        microsoftClientID: "00000000-0000-0000-0000-000000000000"
    )

    func testGoogleSettings() throws {
        let s = try OAuthProviderSettings.settings(for: .google, clients: clients)
        XCTAssertEqual(s.clientID, clients.googleClientID)
        XCTAssertEqual(s.issuer, URL(string: "https://accounts.google.com")!)
        XCTAssertEqual(s.scopes, ["https://mail.google.com/", "openid", "email"])
        XCTAssertEqual(s.redirectURL.absoluteString,
                       "com.googleusercontent.apps.123456789012-abcdefghijklmnop:/oauth2redirect")
        XCTAssertFalse(s.omitIssuer)
    }

    func testMicrosoftSettings() throws {
        let s = try OAuthProviderSettings.settings(for: .microsoft, clients: clients)
        XCTAssertEqual(s.clientID, "00000000-0000-0000-0000-000000000000")
        XCTAssertEqual(s.issuer, URL(string: "https://login.microsoftonline.com/common/v2.0")!)
        XCTAssertEqual(s.scopes,
                       ["https://outlook.office.com/IMAP.AccessAsUser.All", "offline_access", "openid", "email"])
        // CONTRACTS §2: msauth.io.github.rkceve.onepass://auth
        XCTAssertEqual(s.redirectURL.absoluteString, "msauth.io.github.rkceve.onepass://auth")
        XCTAssertTrue(s.omitIssuer)
    }

    func testMissingClientIDs() {
        let none = OAuthClientConfiguration(googleClientID: nil, microsoftClientID: nil)
        XCTAssertThrowsError(try OAuthProviderSettings.settings(for: .google, clients: none)) {
            XCTAssertEqual($0 as? OAuthError, .missingClientID(.google))
        }
        XCTAssertThrowsError(try OAuthProviderSettings.settings(for: .microsoft, clients: none)) {
            XCTAssertEqual($0 as? OAuthError, .missingClientID(.microsoft))
        }
    }

    func testInvalidGoogleClientIDFails() {
        let bad = OAuthClientConfiguration(googleClientID: "not-a-google-client", microsoftClientID: nil)
        XCTAssertThrowsError(try OAuthProviderSettings.settings(for: .google, clients: bad)) {
            XCTAssertEqual($0 as? OAuthError, .invalidGoogleClientID)
        }
    }

    func testIMAPHasNoOAuthProvider() {
        XCTAssertThrowsError(try OAuthProviderSettings.settings(for: .imap, clients: clients)) {
            XCTAssertEqual($0 as? OAuthError, .unsupportedProvider(.imap))
        }
    }
}

final class AddressFromClaimsTests: XCTestCase {
    func testEmailClaimWins() throws {
        let claims: [String: Any] = ["email": "user@gmail.com", "preferred_username": "other@outlook.com"]
        XCTAssertEqual(try OAuthProviderSettings.address(fromClaims: claims, loginHint: "typed@gmail.com"),
                       "user@gmail.com")
    }

    func testPreferredUsernameWhenNoEmail() throws {
        // Microsoft ID tokens for personal accounts may carry only `preferred_username`.
        let claims: [String: Any] = ["preferred_username": "user@outlook.com"]
        XCTAssertEqual(try OAuthProviderSettings.address(fromClaims: claims, loginHint: nil), "user@outlook.com")
    }

    func testClaimsWithoutAtSignFallBackToTrimmedLoginHint() throws {
        let claims: [String: Any] = ["email": "no-at-sign", "preferred_username": "+15551234567"]
        XCTAssertEqual(try OAuthProviderSettings.address(fromClaims: claims, loginHint: "  typed@hotmail.com \n"),
                       "typed@hotmail.com")
    }

    func testNilClaimsUseLoginHint() throws {
        XCTAssertEqual(try OAuthProviderSettings.address(fromClaims: nil, loginHint: "typed@live.com"),
                       "typed@live.com")
    }

    func testNoAddressAnywhereThrows() {
        XCTAssertThrowsError(try OAuthProviderSettings.address(fromClaims: ["sub": "123"], loginHint: "nobody")) {
            XCTAssertEqual($0 as? OAuthError, .missingAddress)
        }
        XCTAssertThrowsError(try OAuthProviderSettings.address(fromClaims: nil, loginHint: nil)) {
            XCTAssertEqual($0 as? OAuthError, .missingAddress)
        }
    }
}
