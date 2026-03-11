import SwiftUI
import SwiftData

struct VitalsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @AppStorage("glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mmolL.rawValue

    let date: Date
    let vitals: DailyVitals?

    @State private var weightText: String = ""
    @State private var systolic: String = ""
    @State private var diastolic: String = ""
    @State private var hr: String = ""
    @State private var glucose: String = ""
    @State private var savedAt: Date? = nil

    private var glucoseUnit: GlucoseUnit { GlucoseUnit(rawValue: glucoseUnitRaw) ?? .mmolL }
    private var weightLabel: String { weightUnit == "lbs" ? "Weight (lbs)" : "Weight (kg)" }
    private var glucoseLabel: String { "Glucose (\(glucoseUnit.displayName))" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vitals")
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
        .onChange(of: weightUnit) { _, _ in loadVitals() }
        .onChange(of: glucoseUnitRaw) { _, _ in loadVitals() }
    }

    private func loadVitals() {
        guard let v = vitals else { return }

        if let kg = v.weightKg {
            let display = weightUnit == "lbs" ? kg * 2.20462 : kg
            weightText = String(format: "%.1f", display)
        } else {
            weightText = ""
        }

        systolic = v.systolicBP.map { String($0) } ?? ""
        diastolic = v.diastolicBP.map { String($0) } ?? ""
        hr = v.restingHR.map { String($0) } ?? ""

        if let raw = v.glucoseValue {
            let converted = convertGlucose(raw, from: v.glucoseUnit, to: glucoseUnit)
            let fmt = glucoseUnit == .mgdL ? "%.0f" : "%.1f"
            glucose = String(format: fmt, converted)
        } else {
            glucose = ""
        }
    }

    private func saveVitals() {
        let target: DailyVitals
        if let existing = vitals {
            target = existing
        } else {
            target = DailyVitals(date: date)
            modelContext.insert(target)
        }

        if let w = Double(weightText) {
            target.weightKg = weightUnit == "lbs" ? w / 2.20462 : w
        } else {
            target.weightKg = nil
        }

        target.systolicBP = Int(systolic)
        target.diastolicBP = Int(diastolic)
        target.restingHR = Int(hr)

        if let g = Double(glucose) {
            target.glucoseValue = g
            target.glucoseUnit = glucoseUnit
        } else {
            target.glucoseValue = nil
        }

        savedAt = Date()
    }

    /// Convert a glucose reading between units.
    private func convertGlucose(_ value: Double, from: GlucoseUnit, to: GlucoseUnit) -> Double {
        guard from != to else { return value }
        return from == .mmolL ? value * 18.0182 : value / 18.0182
    }
}
