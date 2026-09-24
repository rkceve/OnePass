import Foundation
import OnePassAuth
import OnePassExtraction
import OnePassMail
import OnePassModels
import OnePassServerClient
import OnePassStorage

/// Wiring of the concrete OnePassCore implementations into `OneTimeCodeResolver`.
///
/// This is the only file that names concrete types from I2 (Storage/Mail/Auth),
/// I3 (Extraction) and I5 (ServerClient). The symbols below were written against the
/// agents' specs before their code was on origin/main; adjust only this file if they differ:
///   - OnePassStorage: `MailboxStore()`, `MailboxStore.load() throws -> [MailboxConfig]`,
///     `AppGroupState()`, `AppGroupState.appUserID: String?` (App Group key `rc.appUserID`)
///   - OnePassAuth:    `OAuthCredentialProvider()` conforming to `CredentialProviding`
///   - OnePassMail:    `IMAPMailFetcher(credentials: any CredentialProviding)`: `MailFetching`
///   - OnePassExtraction: `OTPCodeExtractor()`: `CodeExtracting`
///   - OnePassServerClient: `ServerClient(config: ServerClient.Config(baseURL:appToken:appUserID:))`
///     conforming to `CandidateJudging` and `UsageReporting`
enum LiveDependencies {

    /// Info.plist keys (CONTRACTS §2).
    static let serverURLKey = "OnePassServerURL"
    static let appTokenKey = "OnePassAppToken"

    /// Returns nil when the server configuration or the RevenueCat app user ID is missing,
    /// in which case the extension cancels every request silently.
    static func makeResolver(bundle: Bundle = .main) -> OneTimeCodeResolver? {
        guard let urlString = bundle.object(forInfoDictionaryKey: serverURLKey) as? String,
              let baseURL = URL(string: urlString), baseURL.scheme != nil,
              let appToken = bundle.object(forInfoDictionaryKey: appTokenKey) as? String, !appToken.isEmpty,
              let appUserID = AppGroupState().appUserID, !appUserID.isEmpty
        else { return nil }

        let server = ServerClient(config: ServerClient.Config(baseURL: baseURL,
                                                              appToken: appToken,
                                                              appUserID: appUserID))
        return OneTimeCodeResolver(
            mailboxes: { try MailboxStore().load() },
            fetcher: IMAPMailFetcher(credentials: OAuthCredentialProvider()),
            extractor: OTPCodeExtractor(),
            judge: server,
            usage: server
        )
    }
}
