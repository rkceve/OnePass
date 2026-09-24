import Foundation
import OnePassModels

// App-local seams between `AppModel` and the concrete services built in
// `LiveServices.swift` (OnePassStorage / OnePassAuth / OnePassServerClient / RevenueCat).
// `AppModel` depends only on these protocols so it can be unit-tested with fakes.

/// Mailboxes and their secrets (CONTRACTS §4).
@MainActor
protocol AccountServices: AnyObject {
    func loadMailboxes() throws -> [MailboxConfig]
    /// Inserts or replaces the mailbox with the same `id`.
    func saveMailbox(_ mailbox: MailboxConfig) throws
    func deleteMailbox(id: UUID) throws

    func savePassword(_ password: String, mailboxID: UUID) throws
    func password(mailboxID: UUID) -> String?
    /// Removes every secret stored for the mailbox (password and OAuth state).
    func deleteCredentials(mailboxID: UUID) throws

    /// Opens the provider's official sign-in page with `loginHint` prefilled and
    /// stores the resulting auth state for `mailboxID`.
    func signIn(kind: ProviderKind, loginHint: String, mailboxID: UUID) async throws
}

/// One purchasable package of the current RevenueCat offering, reduced to what the UI needs.
struct StorePackageInfo: Hashable, Sendable {
    /// `Package.identifier`; used as `PlanOption.id`.
    var id: String
    /// `StoreProduct.productIdentifier`; matched against active entitlements.
    var productID: String
    var title: String
    var description: String
    var priceString: String
    var price: Decimal
}

/// RevenueCat.
@MainActor
protocol BillingServices: AnyObject {
    /// Configures the SDK once with an anonymous user. Returns the RevenueCat app user ID,
    /// or nil when billing is unavailable (no API key in this build).
    func configure() -> String?
    /// Packages of the current offering (empty when there is none).
    func currentPackages() async throws -> [StorePackageInfo]
    /// Product identifiers behind the customer's active entitlements.
    func activeEntitlementProductIDs() async throws -> Set<String>
    /// Purchases the package with `Package.identifier == packageID`.
    /// Returns false when the user cancelled.
    func purchase(packageID: String) async throws -> Bool
}

/// OnePass server usage endpoint (CONTRACTS §5 `GET /v1/usage`).
@MainActor
protocol UsageServices: AnyObject {
    func currentUsage(appUserID: String) async throws -> UsageSnapshot
}

/// App Group values shared with the extension (CONTRACTS §4).
@MainActor
protocol SharedStateServices: AnyObject {
    func setAppUserID(_ appUserID: String)
    func cachedUsage() -> UsageSnapshot?
    func cacheUsage(_ snapshot: UsageSnapshot)
}

struct AppServicesBundle {
    var accounts: any AccountServices
    var billing: any BillingServices
    var usage: any UsageServices
    var sharedState: any SharedStateServices
}
