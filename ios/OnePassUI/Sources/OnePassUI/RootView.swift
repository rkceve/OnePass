import SwiftUI

enum AppTab: Hashable {
    case home
    case plan
}

/// Entry point for the host app: two native tabs, Home (accounts) and Plan.
/// On iOS 26 the system renders the tab bar as Liquid Glass; nothing is hand-drawn.
public struct RootView: View {
    @State private var store: OnePassUIStore
    @State private var selectedTab: AppTab

    private let accounts: [MailAccount]
    private let plans: [PlanOption]
    private let usage: UsageInfo?

    public init(accounts: [MailAccount], plans: [PlanOption], usage: UsageInfo?, actions: OnePassUIActions) {
        self.accounts = accounts
        self.plans = plans
        self.usage = usage
        // One-time seed of view-owned state; later input changes are pushed
        // into the store by the `.onChange` handlers in `body`.
        self.store = OnePassUIStore(accounts: accounts, plans: plans, usage: usage, actions: actions)
        self.selectedTab = .home
    }

    /// Preview / test entry point with a pre-built store.
    init(store: OnePassUIStore, initialTab: AppTab = .home) {
        self.accounts = store.accounts
        self.plans = store.plans
        self.usage = store.usage
        self.store = store
        self.selectedTab = initialTab
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Copy.tabHome, systemImage: "house.fill", value: AppTab.home) {
                AccountsScreen(store: store)
            }
            Tab(Copy.tabPlan, systemImage: "crown.fill", value: AppTab.plan) {
                PlanScreen(store: store)
            }
        }
        .tint(Theme.accent)
        .onChange(of: accounts) { store.accounts = accounts }
        .onChange(of: plans) { store.plans = plans }
        .onChange(of: usage) { store.usage = usage }
    }
}

#Preview("Root – Home") {
    RootView(store: PreviewData.makeStore())
}

#Preview("Root – Plan") {
    RootView(store: PreviewData.makeStore(), initialTab: .plan)
}
