import SwiftUI

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            content
        }
    }
}

struct SettingsRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .font(.system(size: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Mode Badge

struct ModeBadge: View {
    let mode: ClamshellState

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(mode: mode)
            Text(mode == .closed ? "Clamshell Mode" : "Laptop Mode")
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
    }
}

struct StatusDot: View {
    let mode: ClamshellState

    var body: some View {
        Circle()
            .fill(mode == .closed ? Color.blue : Color.green)
            .frame(width: 6, height: 6)
    }
}
