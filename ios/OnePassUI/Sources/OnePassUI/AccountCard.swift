import SwiftUI

/// One mailbox card. Tapping the summary row expands it in place (accordion).
struct AccountCard: View {
    let account: MailAccount
    let isExpanded: Bool
    let onToggle: @MainActor () -> Void
    let onEdit: @MainActor () -> Void
    let onDelete: @MainActor () async throws -> Void
    let revealPassword: @MainActor () async -> String?

    @State private var isConfirmingDelete: Bool
    @State private var isShowingError: Bool
    @State private var errorMessage: String

    // Explicit init: SDK 27 may not synthesize a memberwise init for views with @State.
    init(
        account: MailAccount,
        isExpanded: Bool,
        onToggle: @escaping @MainActor () -> Void,
        onEdit: @escaping @MainActor () -> Void,
        onDelete: @escaping @MainActor () async throws -> Void,
        revealPassword: @escaping @MainActor () async -> String?
    ) {
        self.account = account
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.revealPassword = revealPassword
        self.isConfirmingDelete = false
        self.isShowingError = false
        self.errorMessage = ""
    }

    var body: some View {
        VStack(spacing: 14) {
            AccountSummaryRow(account: account, isExpanded: isExpanded, onToggle: onToggle)

            if isExpanded {
                VStack(spacing: 14) {
                    if account.kind == .imap, let server = account.server {
                        ServerDetailsBox(
                            address: account.address,
                            server: server,
                            revealPassword: revealPassword
                        )
                    }
                    // OPEN(ui): oauth expanded content not specified. Google / Microsoft
                    // cards show no server rows and only the Delete action (nothing to edit).
                    AccountActionRow(
                        address: account.address,
                        showsEdit: account.kind == .imap,
                        onEdit: onEdit,
                        onDelete: { isConfirmingDelete = true }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .cardSurface()
        .confirmationDialog(Copy.deleteConfirmTitle, isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(Copy.delete, role: .destructive) {
                Task { await performDelete() }
            }
            .accessibilityIdentifier("account.\(account.address).delete.confirm")
            Button(Copy.cancel, role: .cancel) {}
        } message: {
            Text(account.address)
        }
        // OPEN(ui): error presentation style not specified; a plain alert is used.
        .alert(Copy.errorTitle, isPresented: $isShowingError) {
            Button(Copy.ok, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func performDelete() async {
        do {
            try await onDelete()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}

// MARK: - Summary row

private struct AccountSummaryRow: View {
    let account: MailAccount
    let isExpanded: Bool
    let onToggle: @MainActor () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                ProviderIcon(kind: account.kind)

                VStack(alignment: .leading, spacing: 6) {
                    Text(account.address)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    StatusLabel(kind: account.kind, status: account.status)
                }

                Spacer(minLength: 8)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Theme.neutralFill, in: Circle())
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? Copy.collapseAccount : Copy.expandAccount)
        .accessibilityIdentifier("account.\(account.address).expand")
    }
}

/// Status dot + provider label ("Custom domain" / "Google" / "Microsoft").
private struct StatusLabel: View {
    let kind: AccountKind
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dotColor)
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)
            Text(kindLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(statusText)
    }

    private var kindLabel: String {
        switch kind {
        case .imap: Copy.kindCustomDomain
        case .google: Copy.kindGoogle
        case .microsoft: Copy.kindMicrosoft
        }
    }

    // OPEN(ui): the mockups only show the connected state. Non-connected states
    // change the dot color and the accessibility value only; no visible copy yet.
    private var dotColor: Color {
        switch status {
        case .connected: Theme.statusGreen
        case .needsSignIn: .orange
        case .error: Theme.destructive
        }
    }

    private var statusText: String {
        switch status {
        case .connected: Copy.statusConnected
        case .needsSignIn: Copy.statusNeedsSignIn
        case .error(let message): message
        }
    }
}

// MARK: - Actions

private struct AccountActionRow: View {
    let address: String
    let showsEdit: Bool
    let onEdit: @MainActor () -> Void
    let onDelete: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if showsEdit {
                Button(action: onEdit) {
                    Label(Copy.edit, systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.primary)
                        .background(Theme.neutralFill, in: RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("account.\(address).edit")
            }

            Button(role: .destructive, action: onDelete) {
                Label(Copy.delete, systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(Theme.destructive)
                    .background(Theme.destructive.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("account.\(address).delete")
        }
        .font(.headline)
    }
}

#Preview("Card – IMAP expanded") {
    AccountCard(
        account: PreviewData.infoAccount,
        isExpanded: true,
        onToggle: {}, onEdit: {}, onDelete: {}, revealPassword: { "hunter2-demo" }
    )
    .padding()
    .background(PastelBackground())
}

#Preview("Card – Google expanded") {
    AccountCard(
        account: PreviewData.gmailAccount,
        isExpanded: true,
        onToggle: {}, onEdit: {}, onDelete: {}, revealPassword: { nil }
    )
    .padding()
    .background(PastelBackground())
}

#Preview("Card – collapsed") {
    AccountCard(
        account: PreviewData.supportAccount,
        isExpanded: false,
        onToggle: {}, onEdit: {}, onDelete: {}, revealPassword: { nil }
    )
    .padding()
    .background(PastelBackground())
}
