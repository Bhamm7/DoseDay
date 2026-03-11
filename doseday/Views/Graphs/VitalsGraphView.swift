import SwiftUI
import Charts
import SwiftData

struct VitalsGraphView: View {
    @Query(sort: \DailyVitals.date) private var allVitals: [DailyVitals]
    @Query private var allProtocols: [MedicationProtocol]
    @AppStorage("weightUnit") private var weightUnit = "kg"

    @State private var showWeight = true
    @State private var showBP = false
    @State private var showHR = false
    @State private var showGlucose = false
    @State private var dateRange: DateRangeOption = .thirtyDays
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var customEnd: Date = Date()

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

    // Protocol start/end markers within the current date range
    private struct ProtoMarker: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
    }

    private var protocolMarkers: [ProtoMarker] {
        var markers: [ProtoMarker] = []
        for proto in allProtocols {
            if dateInterval.contains(proto.startDate) {
                markers.append(ProtoMarker(date: proto.startDate, label: "S"))
            }
            if let end = proto.endDate, dateInterval.contains(end) {
                markers.append(ProtoMarker(date: end, label: "E"))
            }
        }
        return markers
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $dateRange) {
                    ForEach(DateRangeOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if dateRange == .custom {
                    VStack(spacing: 4) {
                        DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
                        DatePicker("To", selection: $customEnd, in: customStart..., displayedComponents: .date)
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 8) {
                    MetricToggle(label: "Weight", color: .blue, isOn: $showWeight)
                    MetricToggle(label: "BP", color: .red, isOn: $showBP)
                    MetricToggle(label: "HR", color: .pink, isOn: $showHR)
                    MetricToggle(label: "Glucose", color: .orange, isOn: $showGlucose)
                }
                .padding(.horizontal)

                if filteredVitals.isEmpty {
                    ContentUnavailableView(
                        "No Vitals",
                        systemImage: "heart.text.square",
                        description: Text("Log vitals from the Day view to see trends here.")
                    )
                    .padding()
                } else {
                    if showWeight {
                        let data = filteredVitals.filter { $0.weightKg != nil }
                        if !data.isEmpty { weightChart(data: data) }
                    }
                    if showBP {
                        let data = filteredVitals.filter { $0.systolicBP != nil }
                        if !data.isEmpty { bpChart(data: data) }
                    }
                    if showHR {
                        let data = filteredVitals.filter { $0.restingHR != nil }
                        if !data.isEmpty { hrChart(data: data) }
                    }
                    if showGlucose {
                        let data = filteredVitals.filter { $0.glucoseValue != nil }
                        if !data.isEmpty { glucoseChart(data: data) }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func displayWeight(_ kg: Double) -> Double {
        weightUnit == "lbs" ? kg * 2.20462 : kg
    }

    @ViewBuilder
    private func weightChart(data: [DailyVitals]) -> some View {
        let unit = weightUnit
        chartSection(title: "Weight (\(unit))") {
            Chart {
                ForEach(data) { v in
                    let w = displayWeight(v.weightKg!)
                    PointMark(x: .value("Date", v.date), y: .value(unit, w))
                        .foregroundStyle(.blue)
                    LineMark(x: .value("Date", v.date), y: .value(unit, w))
                        .foregroundStyle(.blue.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(protocolMarkers) { m in
                    RuleMark(x: .value("Protocol", m.date))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
        }
    }

    @ViewBuilder
    private func bpChart(data: [DailyVitals]) -> some View {
        chartSection(title: "Blood Pressure (mmHg)") {
            Chart {
                ForEach(data) { v in
                    PointMark(x: .value("Date", v.date), y: .value("Systolic", v.systolicBP!))
                        .foregroundStyle(.red)
                    LineMark(x: .value("Date", v.date), y: .value("Systolic", v.systolicBP!))
                        .foregroundStyle(.red.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(data.filter { $0.diastolicBP != nil }) { v in
                    PointMark(x: .value("Date", v.date), y: .value("Diastolic", v.diastolicBP!))
                        .foregroundStyle(.orange)
                    LineMark(x: .value("Date", v.date), y: .value("Diastolic", v.diastolicBP!))
                        .foregroundStyle(.orange.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(protocolMarkers) { m in
                    RuleMark(x: .value("Protocol", m.date))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
        }
    }

    @ViewBuilder
    private func hrChart(data: [DailyVitals]) -> some View {
        chartSection(title: "Resting HR (bpm)") {
            Chart {
                ForEach(data) { v in
                    PointMark(x: .value("Date", v.date), y: .value("bpm", v.restingHR!))
                        .foregroundStyle(.pink)
                    LineMark(x: .value("Date", v.date), y: .value("bpm", v.restingHR!))
                        .foregroundStyle(.pink.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(protocolMarkers) { m in
                    RuleMark(x: .value("Protocol", m.date))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
        }
    }

    @ViewBuilder
    private func glucoseChart(data: [DailyVitals]) -> some View {
        let unit = data.first?.glucoseUnit.displayName ?? ""
        chartSection(title: "Glucose (\(unit))") {
            Chart {
                ForEach(data) { v in
                    PointMark(x: .value("Date", v.date), y: .value("Glucose", v.glucoseValue!))
                        .foregroundStyle(.orange)
                    LineMark(x: .value("Date", v.date), y: .value("Glucose", v.glucoseValue!))
                        .foregroundStyle(.orange.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(protocolMarkers) { m in
                    RuleMark(x: .value("Protocol", m.date))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
        }
    }

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

private struct MetricToggle: View {
    let label: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
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
