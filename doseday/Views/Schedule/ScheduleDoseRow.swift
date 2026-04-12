import SwiftUI

struct ScheduleDoseRow: View {
    @Bindable var event: DoseEvent

    var body: some View {
        HStack(spacing: 10) {
            // Time
            Text(event.scheduledAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(DDTheme.textSecondary)
                .frame(width: 52, alignment: .trailing)

            // Drug color bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: event.drug?.colorHex ?? "#999999"))
                .frame(width: 3, height: 36)

            // Drug info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.drug?.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DDTheme.textPrimary)

                HStack(spacing: 4) {
                    if let schedule = event.drug?.schedule {
                        Text("\(schedule.doseAmount.formatted()) \(schedule.doseUnit)")
                            .font(.caption)
                            .foregroundStyle(DDTheme.textTertiary)
                    }
                    if let site = event.resolvedInjectionSite {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(DDTheme.textTertiary)
                        Text(site.displayName)
                            .font(.caption)
                            .foregroundStyle(DDTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Status + action
            if event.status == .scheduled {
                Button {
                    event.status = .taken
                    event.takenAt = Date()
                } label: {
                    Text("Take")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DDTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusSmall))
                }
                .buttonStyle(.plain)
            } else {
                StatusTagView(status: event.status)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.drug?.name ?? "Dose") at \(event.scheduledAt.formatted(.dateTime.hour().minute())), \(event.status.rawValue)")
    }
}
