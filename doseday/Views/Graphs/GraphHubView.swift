import SwiftUI

enum DateRangeOption: String, CaseIterable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case custom = "Custom"

    /// Number of days to look back. Only meaningful for non-custom cases.
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .custom: return 30
        }
    }
}

struct GraphHubView: View {
    var body: some View {
        UnifiedGraphView()
            .navigationTitle("Graphs")
    }
}
