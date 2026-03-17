import SwiftUI
import Charts
import SwiftData

struct UnifiedGraphView: View {
    @Query(sort: \DailyVitals.date)  private var allVitals: [DailyVitals]
    @Query private var allDrugs: [Drug]
    @Query private var allEvents: [DoseEvent]
    @Query(sort: \LabResult.date) private var allLabResults: [LabResult]
    @Query(sort: \DailySymptom.date) private var allSymptoms: [DailySymptom]
    @Query private var allProtocols: [MedicationProtocol]
    @Query(sort: \SymptomTag.sortOrder) private var allTags: [SymptomTag]

    @AppStorage("weightUnit") private var weightUnit = "kg"

    @State private var dateRange: DateRangeOption = .thirtyDays
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var customEnd: Date = Date()

    // Drug chip selection
    @State private var selectedDrugIds: Set<UUID> = []

    // Adherence toggle
    @State private var showAdherence = true

    // Vital toggles
    @State private var showWeight  = true
    @State private var showBP      = false
    @State private var showHR      = false
    @State private var showGlucose = false

    // Lab marker toggles (keyed by test name)
    @State private var enabledLabTests: Set<String> = []
    @State private var showOnlyOutOfRangeLabs = false

    // Symptom tag toggles
    @State private var enabledTagIds: Set<UUID> = []

    // MARK: - Computed helpers

    private var dateInterval: DateInterval {
        if dateRange == .custom {
            let s = min(customStart, customEnd)
            let e = max(customStart, customEnd)
            return DateInterval(start: s, end: e.addingTimeInterval(86400))
        }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: end)!
        return DateInterval(start: start, end: end)
    }

    private var filteredVitals: [DailyVitals] {
        allVitals.filter { dateInterval.contains($0.date) }
    }

    private var filteredLabResults: [LabResult] {
        allLabResults.filter { dateInterval.contains($0.date) }
    }

    private var selectableLabResults: [LabResult] {
        filteredLabResults.filter { !showOnlyOutOfRangeLabs || $0.isOutOfRange }
    }

    private var filteredSymptoms: [DailySymptom] {
        allSymptoms.filter { dateInterval.contains($0.date) }
    }

    private var labTestNames: [String] {
        Array(Set(selectableLabResults.map(\.testName))).sorted()
    }

    private var selectedDrugs: [Drug] {
        allDrugs.filter { selectedDrugIds.contains($0.id) && $0.halfLifeHours > 0 }
    }

    private var serumSeries: [(drug: Drug, points: [SerumDataPoint])] {
        let calc = SerumCalculator()
        return selectedDrugs.map { drug in
            let events = allEvents.filter { $0.drug?.id == drug.id }
            return (drug, calc.calculate(for: drug, events: events, in: dateInterval))
        }
    }

    // MARK: - Adherence

    private struct AdherencePoint: Identifiable {
        let id = UUID()
        let date: Date
        let drugId: UUID
        let colorHex: String
        let taken: Int
        let total: Int
    }

    private var adherencePoints: [AdherencePoint] {
        let eventsInRange = allEvents.filter { dateInterval.contains($0.scheduledAt) }
        var groups: [String: (date: Date, drug: Drug, taken: Int, total: Int)] = [:]
        for event in eventsInRange {
            guard let drug = event.drug else { continue }
            let day = Calendar.current.startOfDay(for: event.scheduledAt)
            let key = "\(day.timeIntervalSince1970)-\(drug.id)"
            var g = groups[key] ?? (day, drug, 0, 0)
            g.total += 1
            if event.status == .taken { g.taken += 1 }
            groups[key] = g
        }
        return groups.values.map {
            AdherencePoint(date: $0.date, drugId: $0.drug.id, colorHex: $0.drug.colorHex,
                           taken: $0.taken, total: $0.total)
        }.sorted { $0.date < $1.date }
    }

    private var drugsWithoutHalfLife: [Drug] {
        allDrugs.filter { selectedDrugIds.contains($0.id) && $0.halfLifeHours <= 0 }
    }

    // Protocol start/end markers
    private struct ProtoMarker: Identifiable {
        let id = UUID(); let date: Date; let label: String
    }
    private var protocolMarkers: [ProtoMarker] {
        allProtocols.flatMap { proto -> [ProtoMarker] in
            var m: [ProtoMarker] = []
            if dateInterval.contains(proto.startDate) { m.append(ProtoMarker(date: proto.startDate, label: "S")) }
            if let e = proto.endDate, dateInterval.contains(e) { m.append(ProtoMarker(date: e, label: "E")) }
            return m
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterSection
                chartsSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Filter section (chips + date range)

    @ViewBuilder
    private var filterSection: some View {
        // Compounds
        if !allDrugs.isEmpty {
            chipSectionHeader("Compounds")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allDrugs) { drug in
                        let sel = selectedDrugIds.contains(drug.id)
                        Button {
                            if sel { selectedDrugIds.remove(drug.id) }
                            else   { selectedDrugIds.insert(drug.id) }
                        } label: {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: drug.colorHex)).frame(width: 8, height: 8)
                                Text(drug.name).font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(sel ? Color(hex: drug.colorHex).opacity(0.15) : Color.secondary.opacity(0.1))
                            .overlay { Capsule().strokeBorder(sel ? Color(hex: drug.colorHex) : Color.clear, lineWidth: 1.5) }
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(drug.name)
                        .accessibilityValue(sel ? "Selected" : "Not selected")
                    }
                }
                .padding(.horizontal)
            }
        }

        // Metrics
        chipSectionHeader("Metrics")
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MetricToggleChip(label: "Adherence", color: .teal,   isOn: $showAdherence)
                MetricToggleChip(label: "Weight",    color: .blue,   isOn: $showWeight)
                MetricToggleChip(label: "BP",        color: .red,    isOn: $showBP)
                MetricToggleChip(label: "HR",        color: .pink,   isOn: $showHR)
                MetricToggleChip(label: "Glucose",   color: .orange, isOn: $showGlucose)
            }
            .padding(.horizontal)
        }

        // Labs
        if !labTestNames.isEmpty {
            chipSectionHeader("Labs")
            HStack(spacing: 8) {
                MetricToggleChip(label: "Out of Range Only", color: .orange, isOn: $showOnlyOutOfRangeLabs)
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(labTestNames, id: \.self) { name in
                        let on = enabledLabTests.contains(name)
                        Button {
                            if on { enabledLabTests.remove(name) }
                            else  { enabledLabTests.insert(name) }
                        } label: {
                            Text(name)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(on ? Color.purple.opacity(0.15) : Color.secondary.opacity(0.1))
                                .overlay { Capsule().strokeBorder(on ? Color.purple : Color.clear, lineWidth: 1.5) }
                                .clipShape(Capsule())
                                .foregroundStyle(on ? .purple : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }

        // Symptoms
        if !allTags.isEmpty {
            chipSectionHeader("Symptoms")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags) { tag in
                        let on = enabledTagIds.contains(tag.id)
                        Button {
                            if on { enabledTagIds.remove(tag.id) }
                            else  { enabledTagIds.insert(tag.id) }
                        } label: {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: tag.colorHex)).frame(width: 8, height: 8)
                                Text(tag.name).font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(on ? Color(hex: tag.colorHex).opacity(0.15) : Color.secondary.opacity(0.1))
                            .overlay { Capsule().strokeBorder(on ? Color(hex: tag.colorHex) : Color.clear, lineWidth: 1.5) }
                            .clipShape(Capsule())
                            .foregroundStyle(on ? Color(hex: tag.colorHex) : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }

        // Half-life warnings
        if !drugsWithoutHalfLife.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(drugsWithoutHalfLife) { drug in
                    Label("\(drug.name): half-life not set — edit the drug to add it.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)
        }

        // Date range
        Picker("Range", selection: $dateRange) {
            ForEach(DateRangeOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        if dateRange == .custom {
            VStack(spacing: 4) {
                DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
                DatePicker("To",   selection: $customEnd, in: customStart..., displayedComponents: .date)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Charts section

    @ViewBuilder
    private var chartsSection: some View {
        adherenceAndSerumCharts
        vitalsCharts
        labAndSymptomCharts
    }

    @ViewBuilder
    private var adherenceAndSerumCharts: some View {
        // Adherence
        if showAdherence && !adherencePoints.isEmpty {
            adherenceChart
        }

        // Serum
        if !serumSeries.isEmpty && serumSeries.contains(where: { !$0.points.isEmpty }) {
            chartSection(title: "Serum Estimates") {
                Chart {
                    ForEach(serumSeries, id: \.drug.id) { series in
                        ForEach(series.points) { pt in
                            LineMark(x: .value("Date", pt.date), y: .value("Level", pt.level))
                                .foregroundStyle(Color(hex: series.drug.colorHex))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    protoRuleMarks
                }
                .chartYAxisLabel("Relative Level")
            }
            Text("Visual estimate only — not medical advice.")
                .font(.caption2).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var adherenceDrugIds: [UUID] {
        Array(Set(adherencePoints.map { $0.drugId }))
    }

    @ViewBuilder
    private var adherenceChart: some View {
        let drugIds = adherenceDrugIds
        chartSection(title: "Dose Adherence") {
            Chart {
                ForEach(drugIds, id: \.self) { drugId in
                    adherenceMarks(for: drugId)
                }
                protoRuleMarks
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("% taken")
        }
    }
    
    @ChartContentBuilder
    private func adherenceMarks(for drugId: UUID) -> some ChartContent {
        let pts = adherencePoints.filter { $0.drugId == drugId }
        ForEach(pts) { pt in
            let rate = pt.total > 0 ? Double(pt.taken) / Double(pt.total) * 100 : 0
            let color = Color(hex: pt.colorHex)
            
            LineMark(
                x: .value("Date", pt.date, unit: .day),
                y: .value("%", rate)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", pt.date, unit: .day),
                y: .value("%", rate)
            )
            .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var vitalsCharts: some View {
        // Weight
        if showWeight {
            let data = filteredVitals.filter { $0.weightKg != nil }
            if !data.isEmpty {
                let unit = weightUnit
                chartSection(title: "Weight (\(unit))") {
                    Chart {
                        ForEach(data) { v in
                            let w = unit == "lbs" ? v.weightKg! * 2.20462 : v.weightKg!
                            PointMark(x: .value("Date", v.date), y: .value(unit, w)).foregroundStyle(.blue)
                            LineMark(x: .value("Date", v.date), y: .value(unit, w))
                                .foregroundStyle(.blue.opacity(0.5)).interpolationMethod(.catmullRom)
                        }
                        protoRuleMarks
                    }
                }
            }
        }

        // BP
        if showBP {
            let data = filteredVitals.filter { $0.systolicBP != nil }
            if !data.isEmpty {
                chartSection(title: "Blood Pressure (mmHg)") {
                    Chart {
                        ForEach(data) { v in
                            PointMark(x: .value("Date", v.date), y: .value("Systolic", v.systolicBP!)).foregroundStyle(.red)
                            LineMark(x: .value("Date", v.date), y: .value("Systolic", v.systolicBP!))
                                .foregroundStyle(.red.opacity(0.5)).interpolationMethod(.catmullRom)
                        }
                        ForEach(data.filter { $0.diastolicBP != nil }) { v in
                            PointMark(x: .value("Date", v.date), y: .value("Diastolic", v.diastolicBP!)).foregroundStyle(.orange)
                            LineMark(x: .value("Date", v.date), y: .value("Diastolic", v.diastolicBP!))
                                .foregroundStyle(.orange.opacity(0.5)).interpolationMethod(.catmullRom)
                        }
                        protoRuleMarks
                    }
                }
            }
        }

        // HR
        if showHR {
            let data = filteredVitals.filter { $0.restingHR != nil }
            if !data.isEmpty {
                chartSection(title: "Resting HR (bpm)") {
                    Chart {
                        ForEach(data) { v in
                            PointMark(x: .value("Date", v.date), y: .value("bpm", v.restingHR!)).foregroundStyle(.pink)
                            LineMark(x: .value("Date", v.date), y: .value("bpm", v.restingHR!))
                                .foregroundStyle(.pink.opacity(0.5)).interpolationMethod(.catmullRom)
                        }
                        protoRuleMarks
                    }
                }
            }
        }

        // Glucose
        if showGlucose {
            let data = filteredVitals.filter { $0.glucoseValue != nil }
            if !data.isEmpty {
                let gunit = data.first?.glucoseUnit.displayName ?? ""
                chartSection(title: "Glucose (\(gunit))") {
                    Chart {
                        ForEach(data) { v in
                            PointMark(x: .value("Date", v.date), y: .value("Glucose", v.glucoseValue!)).foregroundStyle(.orange)
                            LineMark(x: .value("Date", v.date), y: .value("Glucose", v.glucoseValue!))
                                .foregroundStyle(.orange.opacity(0.5)).interpolationMethod(.catmullRom)
                        }
                        protoRuleMarks
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var labAndSymptomCharts: some View {
        // Lab markers
        ForEach(labTestNames.filter { enabledLabTests.contains($0) }, id: \.self) { testName in
            let data = selectableLabResults.filter { $0.testName == testName }
            if !data.isEmpty {
                let unit = data.first?.unit ?? ""
                chartSection(title: "\(testName) (\(unit))") {
                    Chart {
                        ForEach(data) { r in
                            PointMark(x: .value("Date", r.date), y: .value(testName, r.value))
                                .foregroundStyle(.purple)
                        }
                        if let low = data.compactMap(\.referenceRangeLow).first {
                            RuleMark(y: .value("Ref Low", low))
                                .foregroundStyle(.green.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .annotation(position: .trailing) { Text("Low").font(.caption2).foregroundStyle(.green) }
                        }
                        if let high = data.compactMap(\.referenceRangeHigh).first {
                            RuleMark(y: .value("Ref High", high))
                                .foregroundStyle(.red.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .annotation(position: .trailing) { Text("High").font(.caption2).foregroundStyle(.red) }
                        }
                        protoRuleMarks
                    }
                }
            }
        }

        // Symptoms timeline
        let activeTagIds = enabledTagIds
        let symptomsToShow = filteredSymptoms.filter {
            guard let tagId = $0.tag?.id else { return false }
            return activeTagIds.contains(tagId)
        }
        if !symptomsToShow.isEmpty {
            symptomsTimeline(symptoms: symptomsToShow)
        }
    }

    // MARK: - Protocol rule marks (inline ChartContent)

    @ChartContentBuilder
    private var protoRuleMarks: some ChartContent {
        ForEach(protocolMarkers) { m in
            RuleMark(x: .value("Protocol", m.date))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
        }
    }

    // MARK: - Symptoms timeline

    private func symptomsTimeline(symptoms: [DailySymptom]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptoms")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)

            Chart {
                ForEach(symptoms) { s in
                    let tagColor = Color(hex: s.tag?.colorHex ?? "#8E8E93")
                    PointMark(
                        x: .value("Date", s.date),
                        y: .value("Tag", s.tag?.name ?? "")
                    )
                    .foregroundStyle(tagColor)
                    .symbolSize(CGFloat(s.severity) * 60)
                }
            }
            .frame(height: max(CGFloat(Set(symptoms.compactMap(\.tag?.name)).count) * 28, 60))
            .padding(.horizontal)
        }
    }

    // MARK: - Section header

    @ViewBuilder
    private func chipSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }

    // MARK: - Chart section container

    @ViewBuilder
    private func chartSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)
            content()
                .frame(height: 180)
                .padding(.horizontal)
        }
    }
}

// MARK: - Metric toggle chip (local, avoids collision with VitalsGraphView)

private struct MetricToggleChip: View {
    let label: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isOn ? color.opacity(0.15) : Color.secondary.opacity(0.1))
                .overlay { Capsule().strokeBorder(isOn ? color : Color.clear, lineWidth: 1.5) }
                .clipShape(Capsule())
                .foregroundStyle(isOn ? color : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
    }
}
