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

enum StatsSection: String, CaseIterable {
    case overview = "Overview"
    case compare = "Compare"
    case labs = "Labs"
}

struct GraphHubView: View {
    @State private var selectedSection: StatsSection = .overview

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSection) {
                ForEach(StatsSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            switch selectedSection {
            case .overview:
                StatsOverviewView(
                    onOpenCompare: { selectedSection = .compare },
                    onOpenLabs: { selectedSection = .labs }
                )
            case .compare:
                UnifiedGraphView()
            case .labs:
                LabsView()
            }
        }
        .navigationTitle("Stats")
    }
}
