import AuthenticationServices
import Foundation

/// Supplies the site domains for which one-time-code identities are registered (CONTRACTS §6 step 5).
// OPEN(domains): the source of site domains is undecided (spec §11.2); no concrete source exists yet.
protocol IdentityDomainSource: Sendable {
    func domains() async -> [String]
}

/// Registers `ASOneTimeCodeCredentialIdentity` entries so that iOS offers OnePass in
/// one-time-code fields of matching sites (spec §6a: background, no UI).
struct IdentityRegistrar: Sendable {
    let domainSource: any IdentityDomainSource

    enum Result: Sendable, Equatable {
        case registered(count: Int)
        case storeDisabled
        case nothingToRegister
        case failed
    }

    /// Saves one identity per domain for the given mailbox addresses.
    func register(mailboxAddresses: [String]) async -> Result {
        guard let label = Self.label(mailboxAddresses: mailboxAddresses) else { return .nothingToRegister }
        let domains = Array(Set(await domainSource.domains().filter { !$0.isEmpty })).sorted()
        guard !domains.isEmpty else { return .nothingToRegister }

        let identities: [any ASCredentialIdentity] = domains.map { domain in
            ASOneTimeCodeCredentialIdentity(
                serviceIdentifier: ASCredentialServiceIdentifier(identifier: domain, type: .domain),
                label: label,
                recordIdentifier: Self.recordIdentifier(domain: domain)
            )
        }

        let state = await Self.storeState()
        guard state.isEnabled else { return .storeDisabled }
        let saved = await Self.save(identities, incremental: state.supportsIncrementalUpdates)
        return saved ? .registered(count: identities.count) : .failed
    }

    /// The QuickType label for an identity (CONTRACTS §6: `From <mailbox address>`).
    // OPEN(label): labelling with several registered mailboxes is undecided (spec §11.3:
    // one suggestion per mailbox, or one per site). Until decided, the first address is used.
    static func label(mailboxAddresses: [String]) -> String? {
        guard let first = mailboxAddresses.first else { return nil }
        return "From \(first)"
    }

    static func recordIdentifier(domain: String) -> String {
        "otp.\(domain)"
    }

    // MARK: - ASCredentialIdentityStore (docs/facts/F1 §1)

    private struct StoreState: Sendable {
        var isEnabled: Bool
        var supportsIncrementalUpdates: Bool
    }

    private static func storeState() async -> StoreState {
        await withCheckedContinuation { (continuation: CheckedContinuation<StoreState, Never>) in
            ASCredentialIdentityStore.shared.getState { state in
                continuation.resume(returning: StoreState(isEnabled: state.isEnabled,
                                                          supportsIncrementalUpdates: state.supportsIncrementalUpdates))
            }
        }
    }

    /// Incremental save when the store supports it; otherwise the full set replaces the store.
    private static func save(_ identities: [any ASCredentialIdentity], incremental: Bool) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            if incremental {
                ASCredentialIdentityStore.shared.saveCredentialIdentities(identities) { ok, _ in
                    continuation.resume(returning: ok)
                }
            } else {
                ASCredentialIdentityStore.shared.replaceCredentialIdentities(identities) { ok, _ in
                    continuation.resume(returning: ok)
                }
            }
        }
    }
}
