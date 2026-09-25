import SwiftUI

/// App icon tile, title, subtitle and the glass gear button (shared by both tabs).
struct HeaderView: View {
    let onSettings: @MainActor () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            AppIconTile()

            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.appName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                Text(Copy.appSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            // OPEN(ui): settings screen contents are [Open] (SPEC_v2 §11.1); the
            // button only forwards to the host app.
            SettingsButton(onSettings: onSettings)
                .accessibilityLabel(Copy.settingsLabel)
                .accessibilityIdentifier("header.settings")
        }
    }
}

/// Circular gear button: system `.glass` button style on iOS 26+, material circle before.
private struct SettingsButton: View {
    let onSettings: @MainActor () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
        } else {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: Circle())
        }
    }
}

/// Placeholder app icon. OPEN(ui): final app icon artwork (app name is [Open]).
private struct AppIconTile: View {
    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: 30))
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.accentPink, Theme.accent, Theme.accentBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.10), radius: 10, x: 0, y: 4)
            .accessibilityHidden(true)
    }
}

#Preview("Header", traits: .sizeThatFitsLayout) {
    HeaderView(onSettings: {})
        .padding()
        .background(PastelBackground())
}
