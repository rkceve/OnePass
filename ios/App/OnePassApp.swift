import OnePassUI
import SwiftUI

@main
struct OnePassApp: App {
    @State private var model = AppModel(services: LiveServices.make())
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(
                accounts: model.accounts,
                plans: model.plans,
                usage: model.usage,
                actions: model
            )
            .task { await model.start() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await model.didBecomeActive() }
            }
        }
    }
}
