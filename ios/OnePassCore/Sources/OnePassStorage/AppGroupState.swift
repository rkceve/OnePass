import Foundation
import OnePassModels

/// Small shared values in the App Group defaults (CONTRACTS §4):
/// `rc.appUserID` (written by the app, read by the extension) and `usage.snapshot.v1`.
public final class AppGroupState: @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public convenience init() throws {
        guard let defaults = StorageConstants.sharedDefaults() else {
            throw StorageError.appGroupUnavailable
        }
        self.init(defaults: defaults)
    }

    public var revenueCatAppUserID: String? {
        get { defaults.string(forKey: StorageConstants.DefaultsKey.rcAppUserID) }
        set { defaults.set(newValue, forKey: StorageConstants.DefaultsKey.rcAppUserID) }
    }

    /// Last known usage; nil if never stored or unreadable.
    public func usageSnapshot() -> UsageSnapshot? {
        guard let data = defaults.data(forKey: StorageConstants.DefaultsKey.usageSnapshot) else { return nil }
        return try? Self.decoder.decode(UsageSnapshot.self, from: data)
    }

    public func setUsageSnapshot(_ snapshot: UsageSnapshot?) throws {
        guard let snapshot else {
            defaults.removeObject(forKey: StorageConstants.DefaultsKey.usageSnapshot)
            return
        }
        defaults.set(try Self.encoder.encode(snapshot), forKey: StorageConstants.DefaultsKey.usageSnapshot)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
