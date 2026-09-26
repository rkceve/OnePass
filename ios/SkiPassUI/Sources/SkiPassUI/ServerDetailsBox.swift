import SwiftUI

/// Expanded IMAP details: server, port, username and masked password rows.
/// Outgoing rows appear only when the host app provides them.
struct ServerDetailsBox: View {
    let address: String
    let server: ServerSettings
    let revealPassword: @MainActor () async -> String?

    var body: some View {
        VStack(spacing: 0) {
            DetailRow(label: Copy.incomingServer, value: server.incomingHost, chip: .imap)
            if let outgoingHost = server.outgoingHost {
                Divider()
                DetailRow(label: Copy.outgoingServer, value: outgoingHost, chip: .smtp)
            }
            Divider()
            DetailRow(label: Copy.incomingPort, value: String(server.incomingPort))
            if let outgoingPort = server.outgoingPort {
                Divider()
                DetailRow(label: Copy.outgoingPort, value: String(outgoingPort))
            }
            Divider()
            DetailRow(label: Copy.username, value: server.username)
            Divider()
            PasswordRow(address: address, revealPassword: revealPassword)
        }
        .padding(.horizontal, 16)
        .background(Theme.innerFill, in: RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))
    }
}

enum ProtocolChip {
    case imap
    case smtp

    var title: String {
        switch self {
        case .imap: Copy.chipIMAP
        case .smtp: Copy.chipSMTP
        }
    }

    var color: Color {
        switch self {
        case .imap: Theme.chipIMAPForeground
        case .smtp: Theme.chipSMTPForeground
        }
    }
}

/// Label / value row with an optional protocol chip.
private struct DetailRow: View {
    let label: String
    let value: String
    var chip: ProtocolChip?

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 128, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let chip {
                ChipView(title: chip.title, color: chip.color)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

/// Static tinted capsule ("IMAP", "SMTP", "Current"). Content, not a control,
/// so it is intentionally not Liquid Glass.
struct ChipView: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

/// Masked password with an eye toggle that asks the host app for the secret.
private struct PasswordRow: View {
    let address: String
    let revealPassword: @MainActor () async -> String?

    @State private var revealed: String?

    init(address: String, revealPassword: @escaping @MainActor () async -> String?) {
        self.address = address
        self.revealPassword = revealPassword
        self.revealed = nil
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(Copy.password)
                .foregroundStyle(.secondary)
                .frame(width: 128, alignment: .leading)
            Text(revealed ?? Copy.passwordMask)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(revealed == nil)
            Button {
                Task { await toggle() }
            } label: {
                Image(systemName: revealed == nil ? "eye" : "eye.slash")
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealed == nil ? Copy.showPassword : Copy.hidePassword)
            .accessibilityIdentifier("account.\(address).password.reveal")
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }

    private func toggle() async {
        if revealed == nil {
            revealed = await revealPassword()
        } else {
            revealed = nil
        }
    }
}
