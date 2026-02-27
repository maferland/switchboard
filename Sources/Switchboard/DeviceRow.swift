import SwiftUI

struct DeviceRow: View {
    let icon: String
    let name: String
    let detail: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(isActive ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .lineLimit(1)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isActive ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
