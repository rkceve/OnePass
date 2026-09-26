import SwiftUI

/// Screen 2 (Plan tab): header, current plan with usage, other plans, Change Plan.
/// Low-pressure by design: nothing beyond what the mockup shows.
struct PlanScreen: View {
    let store: SkiPassUIStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(onSettings: { store.openSettings() })

                SectionTitle(text: Copy.planTitle)

                if let current = store.currentPlan {
                    CurrentPlanCard(plan: current, usage: store.usage, referenceDate: store.referenceDate)
                }

                let others = store.otherPlans
                if !others.isEmpty {
                    SectionTitle(text: Copy.otherPlansTitle)
                        .padding(.top, 8)

                    VStack(spacing: 16) {
                        ForEach(others) { plan in
                            PlanRow(plan: plan) {
                                Task { await store.selectPlan(id: plan.id) }
                            }
                        }
                    }
                }

                ChangePlanRow {
                    // OPEN(ui): Change Plan behavior not specified; intentionally a no-op.
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .tabBarClearance()
        .background(PastelBackground())
    }
}

private struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.largeTitle.bold())
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Plan") {
    PlanScreen(store: PreviewData.makeStore())
}

#Preview("Plan – no usage yet") {
    PlanScreen(store: PreviewData.makeStore(usage: nil))
}
