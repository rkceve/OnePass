import SwiftUI

/// Screen 1 (Home tab): header, "Accounts" + Add, accordion account cards.
struct AccountsScreen: View {
    @Bindable var store: OnePassUIStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(onSettings: { store.openSettings() })

                AccountsSectionHeader {
                    store.accountSheet = .add
                }

                VStack(spacing: 16) {
                    ForEach(store.accounts) { account in
                        AccountCard(
                            account: account,
                            isExpanded: store.expandedAccountID == account.id,
                            onToggle: {
                                withAnimation(.smooth) { store.toggleExpanded(account.id) }
                            },
                            onEdit: { store.accountSheet = .edit(account) },
                            onDelete: {
                                try await store.deleteAccount(id: account.id)
                            },
                            revealPassword: {
                                await store.revealPassword(id: account.id)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(PastelBackground())
        .sheet(item: $store.accountSheet) { sheet in
            AccountFormSheet(sheet: sheet, store: store)
        }
    }
}

/// "Accounts" title with the glass "Add" button.
private struct AccountsSectionHeader: View {
    let onAdd: @MainActor () -> Void

    var body: some View {
        HStack {
            Text(Copy.accountsTitle)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: onAdd) {
                Label(Copy.add, systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .glassControl(in: Capsule(), tint: Theme.accent.opacity(0.85))
            .accessibilityLabel(Copy.addAccountLabel)
            .accessibilityIdentifier("accounts.add")
        }
    }
}

#Preview("Accounts – collapsed") {
    AccountsScreen(store: PreviewData.makeStore())
}

#Preview("Accounts – expanded IMAP") {
    AccountsScreen(store: PreviewData.makeStore(expanded: PreviewData.infoAccountID))
}

#Preview("Accounts – expanded Google") {
    AccountsScreen(store: PreviewData.makeStore(expanded: PreviewData.gmailAccountID))
}
