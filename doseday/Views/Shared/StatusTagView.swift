import SwiftUI

struct StatusTagView: View {
    let status: DoseStatus

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(tagColor)
            .background(tagColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusSmall))
    }

    private var label: String {
        switch status {
        case .scheduled: "Scheduled"
        case .taken: "Taken"
        case .skipped: "Skipped"
        }
    }

    private var tagColor: Color {
        switch status {
        case .scheduled: DDTheme.statusPending
        case .taken: DDTheme.statusTaken
        case .skipped: DDTheme.statusSkipped
        }
    }
}
