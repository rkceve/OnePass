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
/// I3 (Extraction) and I5 (ServerClient). Symbols used (same as ios/App/LiveServices.swift):
///   - OnePassStorage: `MailboxStore() throws`, `.list()`; `AppGroupState() throws`, `.revenueCatAppUserID`
///   - OnePassAuth:    `OAuthCredentialProvider()`: `CredentialProviding`
///   - OnePassMail:    `IMAPMailFetcher(credentials:timeout:)`: `MailFetching`
///   - OnePassExtraction: `OTPCodeExtractor()`: `CodeExtracting`
///   - OnePassServerClient: `ServerClient(configuration: ServerClientConfiguration(baseURL:appToken:appUserID:))`,
///     conforming to `CandidateJudging` and `UsageReporting`
enum LiveDependencies {

    /// Info.plist keys (CONTRACTS §2).
    static let serverURLKey = "OnePassServerURL"
    static let appTokenKey = "OnePassAppToken"

    /// Returns nil when the server configuration, the App Group or the RevenueCat app user ID is
    /// missing, in which case the extension cancels every request silently.
    static func makeResolver(bundle: Bundle = .main) -> OneTimeCodeResolver? {
        guard let urlString = value(serverURLKey, in: bundle),
              let baseURL = URL(string: urlString), baseURL.scheme != nil,
              let appToken = value(appTokenKey, in: bundle),
              let sharedState = try? AppGroupState(),
              let appUserID = sharedState.revenueCatAppUserID, !appUserID.isEmpty,
              let mailboxStore = try? MailboxStore()
        else { return nil }

        let server = ServerClient(configuration: ServerClientConfiguration(
            baseURL: baseURL,
            appToken: appToken,
            appUserID: { appUserID }
        ))
        return OneTimeCodeResolver(
            mailboxes: { try mailboxStore.list() },
            // The fetcher's own wall-clock limit matches the resolver's per-mailbox budget
            // (CONTRACTS §6: 4 s), so a timed-out fetch also drops its IMAP connection.
            fetcher: IMAPMailFetcher(credentials: OAuthCredentialProvider(),
                                     timeout: seconds(OneTimeCodeResolver.defaultPerMailboxBudget)),
            extractor: OTPCodeExtractor(),
            judge: server,
            usage: server
        )
    }

    /// Non-empty, substituted Info.plist string (an unset xcconfig variable leaves "" or "$(NAME)").
    private static func value(_ key: String, in bundle: Bundle) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }

    private static func seconds(_ duration: Duration) -> TimeInterval {
        let parts = duration.components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
