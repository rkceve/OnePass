import Foundation

/// Identifiers fixed by docs/CONTRACTS.md §2 and §4.
public enum StorageConstants {
    /// App Group shared by the app and the AutoFill extension.
    public static let appGroupID = "group.io.github.rkceve.onepass"
    /// Keychain access group: same string as the App Group (CONTRACTS §2).
    public static let keychainAccessGroup = appGroupID
    /// Keychain generic-password service (CONTRACTS §4).
    public static let keychainService = "io.github.rkceve.onepass"

    /// UserDefaults keys (CONTRACTS §4).
    public enum DefaultsKey {
        public static let mailboxes = "mailboxes.v1"
        public static let rcAppUserID = "rc.appUserID"
        public static let usageSnapshot = "usage.snapshot.v1"
    }

    /// Keychain account names (CONTRACTS §4).
    public enum KeychainAccount {
        public static func password(_ mailboxID: UUID) -> String { "password.\(mailboxID.uuidString)" }
        public static func oauth(_ mailboxID: UUID) -> String { "oauth.\(mailboxID.uuidString)" }
    }

    /// The shared App Group defaults. Nil when the process lacks the App Group entitlement.
    public static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}

public enum StorageError: Error, Equatable, Sendable {
    /// The App Group container is not available (missing entitlement).
    case appGroupUnavailable
    case mailboxAlreadyExists(UUID)
    case mailboxNotFound(UUID)
    /// A Keychain call returned a non-success OSStatus.
    case keychain(status: Int32)
    /// Stored bytes could not be decoded as UTF-8.
    case invalidPasswordEncoding
}
