import SwiftUI
import Charts
import SwiftData

struct SerumEstimateView: View {
    @Query private var allDrugs: [Drug]
    @Query private var allEvents: [DoseEvent]

    @State private var selectedDrugIds: Set<UUID> = []
    @State private var dateRange: DateRangeOption = .thirtyDays
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var customEnd: Date = Date()

    private var dateInterval: DateInterval {
        if dateRange == .custom {
            let s = min(customStart, customEnd)
            let e = max(customStart, customEnd)
            return DateInterval(start: s, end: e.addingTimeInterval(86400)) // inclusive end
        }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: end)!
        return DateInterval(start: start, end: end)
    }

    private var selectedDrugs: [Drug] {
        allDrugs.filter { selectedDrugIds.contains($0.id) }
    }

    private var drugsWithoutHalfLife: [Drug] {
        selectedDrugs.filter { $0.halfLifeHours <= 0 }
    }

    private var chartSeries: [(drug: Drug, points: [SerumDataPoint])] {
        let calc = SerumCalculator()
        return selectedDrugs.filter { $0.halfLifeHours > 0 }.map { drug in
            let events = allEvents.filter { $0.drug?.id == drug.id }
            return (drug, calc.calculate(for: drug, events: events, in: dateInterval))
        }
    }

    private var hasData: Bool {
        chartSeries.contains { !$0.points.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if allDrugs.isEmpty {
                    ContentUnavailableView(
                        "No Drugs",
                        systemImage: "pills",
                        description: Text("Add a protocol with drugs to see serum estimates.")
                    )
                    .padding()
                } else {
                    // Range picker
                    Picker("Range", selection: $dateRange) {
                        ForEach(DateRangeOption.allCases, id: \.self) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Custom date pickers
                    if dateRange == .custom {
                        VStack(spacing: 4) {
                            DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
                            DatePicker("To", selection: $customEnd, in: customStart..., displayedComponents: .date)
                        }
                        .padding(.horizontal)
                    }

                    // Drug selector chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allDrugs) { drug in
                                let isSelected = selectedDrugIds.contains(drug.id)
                                Button {
                                    if isSelected { selectedDrugIds.remove(drug.id) }
                                    else { selectedDrugIds.insert(drug.id) }
                                } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: drug.colorHex))
                                            .frame(width: 8, height: 8)
                                        Text(drug.name)
                                            .font(.caption.weight(.medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(hex: drug.colorHex).opacity(0.15) : Color.secondary.opacity(0.1))
                                    .overlay {
                                        Capsule().strokeBorder(isSelected ? Color(hex: drug.colorHex) : Color.clear, lineWidth: 1.5)
                                    }
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(drug.name)
                                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Half-life warnings
                    if !drugsWithoutHalfLife.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(drugsWithoutHalfLife) { drug in
                                Label("\(drug.name): half-life not set — edit the drug to add it.", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Chart or empty state
                    if selectedDrugIds.isEmpty {
                        Text("Select a drug above to see its serum estimate.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if !hasData {
                        Text("No taken doses in this date range.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(chartSeries, id: \.drug.id) { series in
                                ForEach(series.points) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Level", point.level)
                                    )
                                    .foregroundStyle(Color(hex: series.drug.colorHex))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                        }
                        .chartYAxisLabel("Relative Level")
                        .frame(height: 240)
                        .padding(.horizontal)

                        Text("Visual estimate only — not medical advice.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
