import SwiftUI

struct StatusPillView: View {
    let status: DoseStatus

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(pillColor.opacity(0.15))
            .foregroundStyle(pillColor)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .scheduled: return "Scheduled"
        case .taken: return "Taken"
        case .skipped: return "Skipped"
        }
    }

    private var pillColor: Color {
        switch status {
        case .scheduled: return .blue
        case .taken: return .green
        case .skipped: return .gray
        }
    }
}
