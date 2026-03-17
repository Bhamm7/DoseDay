import SwiftUI
import SwiftData

struct VitalsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @AppStorage("glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mmolL.rawValue

    let date: Date
    let vitals: DailyVitals?
    var title: String = "Vitals"

    @State private var weightText: String = ""
    @State private var systolic: String = ""
    @State private var diastolic: String = ""
    @State private var hr: String = ""
    @State private var glucose: String = ""
    @State private var savedAt: Date? = nil

    private var glucoseUnit: GlucoseUnit { GlucoseUnit(rawValue: glucoseUnitRaw) ?? .mmolL }
    private var weightLabel: String { VitalsEditorSupport.weightLabel(weightUnit: weightUnit) }
    private var glucoseLabel: String { VitalsEditorSupport.glucoseLabel(glucoseUnit: glucoseUnit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let savedAt {
                    Text("Saved at \(savedAt.formatted(.dateTime.hour().minute()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text(weightLabel)
                        .font(.subheadline)
                    Spacer()
                    TextField("—", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel(weightLabel)
                }

                HStack {
                    Text("Blood Pressure")
                        .font(.subheadline)
                    Spacer()
                    TextField("SYS", text: $systolic)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                        .accessibilityLabel("Systolic blood pressure")
                    Text("/").foregroundStyle(.secondary)
                    TextField("DIA", text: $diastolic)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                        .accessibilityLabel("Diastolic blood pressure")
                }

                HStack {
                    Text("Heart Rate")
                        .font(.subheadline)
                    Spacer()
                    TextField("—", text: $hr)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel("Resting heart rate in beats per minute")
                    Text("bpm").font(.caption).foregroundStyle(.secondary)
                }

                HStack {
                    Text(glucoseLabel)
                        .font(.subheadline)
                    Spacer()
                    TextField("—", text: $glucose)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel(glucoseLabel)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button("Save Vitals") {
                saveVitals()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .onAppear { loadVitals() }
        .onChange(of: date) { _, _ in loadVitals() }
        .onChange(of: vitals?.id) { _, _ in loadVitals() }
        .onChange(of: weightUnit) { _, _ in loadVitals() }
        .onChange(of: glucoseUnitRaw) { _, _ in loadVitals() }
    }

    private func loadVitals() {
        savedAt = nil
        let draft = VitalsDraft(vitals: vitals, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
        weightText = draft.weightText
        systolic = draft.systolic
        diastolic = draft.diastolic
        hr = draft.hr
        glucose = draft.glucose
    }

    private func saveVitals() {
        let draft = VitalsDraft(
            weightText: weightText,
            systolic: systolic,
            diastolic: diastolic,
            hr: hr,
            glucose: glucose
        )

        if vitals == nil && draft.isEmpty {
            return
        }

        let target: DailyVitals
        if let existing = vitals {
            target = existing
        } else {
            target = DailyVitals(date: date)
            modelContext.insert(target)
        }

        target.date = Calendar.current.startOfDay(for: date)

        draft.apply(to: target, weightUnit: weightUnit, glucoseUnit: glucoseUnit)

        savedAt = Date()
    }
}

struct VitalsDraft: Equatable {
    var weightText: String = ""
    var systolic: String = ""
    var diastolic: String = ""
    var hr: String = ""
    var glucose: String = ""

    init(
        weightText: String = "",
        systolic: String = "",
        diastolic: String = "",
        hr: String = "",
        glucose: String = ""
    ) {
        self.weightText = weightText
        self.systolic = systolic
        self.diastolic = diastolic
        self.hr = hr
        self.glucose = glucose
    }

    init(vitals: DailyVitals?, weightUnit: String, glucoseUnit: GlucoseUnit) {
        guard let vitals else {
            self.init()
            return
        }

        var weightText = ""
        if let kg = vitals.weightKg {
            let displayWeight = weightUnit == "lbs" ? kg * 2.20462 : kg
            weightText = String(format: "%.1f", displayWeight)
        }

        let systolic = vitals.systolicBP.map(String.init) ?? ""
        let diastolic = vitals.diastolicBP.map(String.init) ?? ""
        let hr = vitals.restingHR.map(String.init) ?? ""

        var glucose = ""
        if let rawGlucose = vitals.glucoseValue {
            let converted = VitalsEditorSupport.convertGlucose(rawGlucose, from: vitals.glucoseUnit, to: glucoseUnit)
            let format = glucoseUnit == .mgdL ? "%.0f" : "%.1f"
            glucose = String(format: format, converted)
        }

        self.init(
            weightText: weightText,
            systolic: systolic,
            diastolic: diastolic,
            hr: hr,
            glucose: glucose
        )
    }

    var isEmpty: Bool {
        [weightText, systolic, diastolic, hr, glucose]
            .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func apply(to target: DailyVitals, weightUnit: String, glucoseUnit: GlucoseUnit) {
        if let weightValue = Double(weightText) {
            target.weightKg = weightUnit == "lbs" ? weightValue / 2.20462 : weightValue
        } else {
            target.weightKg = nil
        }

        target.systolicBP = Int(systolic)
        target.diastolicBP = Int(diastolic)
        target.restingHR = Int(hr)

        if let glucoseValue = Double(glucose) {
            target.glucoseValue = glucoseValue
            target.glucoseUnit = glucoseUnit
        } else {
            target.glucoseValue = nil
        }
    }
}

enum VitalsEditorSupport {
    static func weightLabel(weightUnit: String) -> String {
        weightUnit == "lbs" ? "Weight (lbs)" : "Weight (kg)"
    }

    static func glucoseLabel(glucoseUnit: GlucoseUnit) -> String {
        "Glucose (\(glucoseUnit.displayName))"
    }

    static func convertGlucose(_ value: Double, from: GlucoseUnit, to: GlucoseUnit) -> Double {
        guard from != to else { return value }
        return from == .mmolL ? value * 18.0182 : value / 18.0182
    }
}
