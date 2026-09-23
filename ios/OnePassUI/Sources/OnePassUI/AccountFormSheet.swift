import SwiftUI

/// Add / edit sheet (no mockup; decided behavior).
/// Add: ask for an email only -> `addAccount(email:)`. If the host throws
/// `OnePassUIError.needsServerSettings`, continue in the same sheet with the IMAP form.
/// Edit (IMAP only): the same IMAP form, prefilled.
struct AccountFormSheet: View {
    private enum Step: Hashable {
        case email
        case imap
    }

    private enum Field: Hashable {
        case email, host, port, username, password
    }

    let store: OnePassUIStore

    @Environment(\.dismiss) private var dismiss

    @State private var step: Step
    @State private var email: String
    @State private var host: String
    @State private var portText: String
    @State private var username: String
    @State private var password: String
    @State private var isWorking: Bool
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private let editingAccount: MailAccount?

    init(sheet: AccountSheet, store: OnePassUIStore) {
        self.store = store
        switch sheet {
        case .add:
            editingAccount = nil
            step = .email
            email = ""
            host = ""
            portText = Copy.defaultIMAPPort
            username = ""
        case .edit(let account):
            editingAccount = account
            step = .imap
            email = account.address
            host = account.server?.incomingHost ?? ""
            portText = account.server.map { String($0.incomingPort) } ?? Copy.defaultIMAPPort
            username = account.server?.username ?? account.address
        }
        password = ""
        isWorking = false
        errorMessage = nil
    }

    var body: some View {
        NavigationStack {
            Form {
                switch step {
                case .email:
                    emailSection
                case .imap:
                    imapSections
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.destructive)
                            .accessibilityIdentifier("accountForm.error")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PastelBackground())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingAccount == nil ? Copy.addAccountTitle : Copy.editAccountTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .disabled(isWorking)
            .task { await prefillPasswordIfEditing() }
        }
    }

    // MARK: Sections

    private var emailSection: some View {
        Section(Copy.emailAddress) {
            TextField(Copy.emailPlaceholder, text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($focusedField, equals: .email)
                .onSubmit { Task { await submit() } }
                .accessibilityIdentifier("accountForm.email")
        }
        .defaultFocus($focusedField, .email)
    }

    @ViewBuilder
    private var imapSections: some View {
        Section(Copy.emailAddress) {
            Text(email)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("accountForm.address")
        }

        Section(Copy.serverSettingsSection) {
            LabeledContent(Copy.incomingServer) {
                TextField(Copy.host, text: $host)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .host)
                    .accessibilityIdentifier("accountForm.host")
            }
            LabeledContent(Copy.incomingPort) {
                TextField(Copy.port, text: $portText)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .port)
                    .accessibilityIdentifier("accountForm.port")
            }
            LabeledContent(Copy.username) {
                TextField(Copy.username, text: $username)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .accessibilityIdentifier("accountForm.username")
            }
            LabeledContent(Copy.password) {
                SecureField(Copy.password, text: $password)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .accessibilityIdentifier("accountForm.password")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(Copy.cancel) { dismiss() }
                .accessibilityIdentifier("accountForm.cancel")
        }
        ToolbarItem(placement: .confirmationAction) {
            if isWorking {
                ProgressView()
            } else {
                Button(step == .email ? Copy.continueAction : Copy.save) {
                    Task { await submit() }
                }
                .disabled(!canSubmit)
                .accessibilityIdentifier(step == .email ? "accountForm.continue" : "accountForm.save")
            }
        }
    }

    // MARK: Logic

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var port: Int? {
        guard let value = Int(portText.trimmingCharacters(in: .whitespaces)), (1...65_535).contains(value) else {
            return nil
        }
        return value
    }

    private var canSubmit: Bool {
        switch step {
        case .email:
            return trimmedEmail.contains("@")
        case .imap:
            return !host.trimmingCharacters(in: .whitespaces).isEmpty
                && port != nil
                && !username.trimmingCharacters(in: .whitespaces).isEmpty
                && !password.isEmpty
        }
    }

    private func submit() async {
        guard canSubmit, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            switch step {
            case .email:
                try await store.addAccount(email: trimmedEmail)
                dismiss()
            case .imap:
                try await saveIMAP()
                dismiss()
            }
        } catch OnePassUIError.needsServerSettings {
            email = trimmedEmail
            if username.isEmpty { username = trimmedEmail }
            withAnimation(.smooth) { step = .imap }
            focusedField = .host
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveIMAP() async throws {
        guard let port else { return }
        // Outgoing values are display-only and not edited here; keep what the host provided.
        let settings = ServerSettings(
            incomingHost: host.trimmingCharacters(in: .whitespaces),
            incomingPort: port,
            username: username.trimmingCharacters(in: .whitespaces),
            outgoingHost: editingAccount?.server?.outgoingHost,
            outgoingPort: editingAccount?.server?.outgoingPort
        )
        try await store.saveIMAP(address: email, settings: settings, password: password)
    }

    private func prefillPasswordIfEditing() async {
        guard let editingAccount, password.isEmpty else { return }
        if let stored = await store.revealPassword(id: editingAccount.id) {
            password = stored
        }
    }
}

#Preview("Add sheet – email step") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AccountFormSheet(sheet: .add, store: PreviewData.makeStore())
        }
}

#Preview("Edit sheet – IMAP") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AccountFormSheet(sheet: .edit(PreviewData.infoAccount), store: PreviewData.makeStore())
        }
}
