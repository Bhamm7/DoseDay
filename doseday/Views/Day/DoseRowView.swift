import SwiftUI

struct DoseRowView: View {
    @Bindable var event: DoseEvent
    let onMarkTaken: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(event.scheduledAt, format: .dateTime.hour().minute())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)

                Circle()
                    .fill(Color(hex: event.drug?.colorHex ?? "#999999"))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.drug?.name ?? "Unknown")
                        .font(.body.weight(.medium))

                    if event.drug?.route == .injection, let site = event.resolvedInjectionSite {
                        Text(site.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                StatusPillView(status: event.status)

                if event.status == .scheduled {
                    Button("Mark taken", action: onMarkTaken)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .accessibilityLabel("Mark \(event.drug?.name ?? "dose") as taken")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityHint("Tap for details")
    }

    private var rowAccessibilityLabel: String {
        let time = event.scheduledAt.formatted(.dateTime.hour().minute())
        let drug = event.drug?.name ?? "Unknown drug"
        let status = event.status.rawValue.capitalized
        return "\(time), \(drug), \(status)"
    }
}
