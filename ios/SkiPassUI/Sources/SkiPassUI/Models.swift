import Foundation

/// How a mailbox signs in. Google and Microsoft use the provider's official
/// sign-in screen; everything else is a plain IMAP account.
public enum AccountKind: Hashable, Sendable {
    case google
    case microsoft
    case imap
}

public enum ConnectionStatus: Hashable, Sendable {
    case connected
    case needsSignIn
    case error(String)
}

/// Server settings for IMAP accounts. Outgoing values are display-only;
/// their rows are shown only when non-nil.
public struct ServerSettings: Hashable, Sendable {
    public var incomingHost: String
    public var incomingPort: Int
    public var username: String
    public var outgoingHost: String?
    public var outgoingPort: Int?

    public init(
        incomingHost: String,
        incomingPort: Int,
        username: String,
        outgoingHost: String? = nil,
        outgoingPort: Int? = nil
    ) {
        self.incomingHost = incomingHost
        self.incomingPort = incomingPort
        self.username = username
        self.outgoingHost = outgoingHost
        self.outgoingPort = outgoingPort
    }
}

public struct MailAccount: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var address: String
    public var kind: AccountKind
    public var status: ConnectionStatus
    /// nil for google / microsoft.
    public var server: ServerSettings?

    public init(
        id: UUID = UUID(),
        address: String,
        kind: AccountKind,
        status: ConnectionStatus,
        server: ServerSettings? = nil
    ) {
        self.id = id
        self.address = address
        self.kind = kind
        self.status = status
        self.server = server
    }
}

public struct PlanOption: Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var tagline: String
    public var priceText: String
    public var isCurrent: Bool
    public var systemImage: String

    public init(
        id: String,
        name: String,
        tagline: String,
        priceText: String,
        isCurrent: Bool,
        systemImage: String
    ) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.priceText = priceText
        self.isCurrent = isCurrent
        self.systemImage = systemImage
    }
}

public struct UsageInfo: Hashable, Sendable {
    public var used: Int
    public var limit: Int
    public var resetsAt: Date

    public init(used: Int, limit: Int, resetsAt: Date) {
        self.used = used
        self.limit = limit
        self.resetsAt = resetsAt
    }

    /// Remaining count, never negative.
    var remaining: Int { max(limit - used, 0) }

    /// Remaining fraction in 0...1 (0 when limit is 0).
    var remainingFraction: Double {
        guard limit > 0 else { return 0 }
        return min(max(Double(remaining) / Double(limit), 0), 1)
    }
}

public enum SkiPassUIError: Error, Hashable, Sendable {
    /// Thrown by `SkiPassUIActions.addAccount(email:)` when the address is not a
    /// Google / Microsoft account and IMAP server settings are required.
    case needsServerSettings
}
