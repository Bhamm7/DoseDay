import SwiftUI
import SwiftData

struct CompactVitalsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @AppStorage("glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mmolL.rawValue

    let date: Date
    let vitals: DailyVitals?

    @State private var weightText = ""
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var hr = ""
    @State private var glucose = ""

    @FocusState private var focusedField: VitalsField?

    private var glucoseUnit: GlucoseUnit { GlucoseUnit(rawValue: glucoseUnitRaw) ?? .mmolL }

    private enum VitalsField: Hashable {
        case weight, systolic, diastolic, hr, glucose
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                vitalsCell(
                    icon: "scalemass",
                    placeholder: weightUnit == "lbs" ? "lbs" : "kg",
                    text: $weightText,
                    field: .weight,
                    keyboard: .decimalPad
                )
                vitalsCell(
                    icon: "heart",
                    placeholder: "bpm",
                    text: $hr,
                    field: .hr,
                    keyboard: .numberPad
                )
            }

            HStack(spacing: 6) {
                // Blood pressure — two fields in one tile
                bpCell()
                vitalsCell(
                    icon: "drop",
                    placeholder: glucoseUnit == .mgdL ? "mg/dL" : "mmol/L",
                    text: $glucose,
                    field: .glucose,
                    keyboard: .decimalPad
                )
            }
        }
        .padding(.horizontal)
        .onAppear { loadDraft() }
        .onChange(of: date) { _, _ in loadDraft() }
        .onChange(of: vitals?.id) { _, _ in loadDraft() }
        .onChange(of: weightUnit) { _, _ in loadDraft() }
        .onChange(of: glucoseUnitRaw) { _, _ in loadDraft() }
        .onChange(of: focusedField) { old, new in
            if old != nil && new == nil {
                persistIfNeeded()
            }
        }
        .onDisappear { persistIfNeeded() }
    }

    // MARK: - Tile builders

    private func vitalsCell(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: VitalsField,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DDTheme.accent)
                .frame(width: 16)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.subheadline.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DDTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: DDTheme.radiusMedium)
                .strokeBorder(
                    focusedField == field ? DDTheme.accent : DDTheme.cardBorder,
                    lineWidth: focusedField == field ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
    }

    private func bpCell() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")
                .font(.caption)
                .foregroundStyle(DDTheme.accent)
                .frame(width: 16)
            TextField("sys", text: $systolic)
                .keyboardType(.numberPad)
                .font(.subheadline.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .systolic)
                .frame(maxWidth: .infinity)
            Text("/")
                .font(.caption)
                .foregroundStyle(DDTheme.textTertiary)
            TextField("dia", text: $diastolic)
                .keyboardType(.numberPad)
                .font(.subheadline.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .diastolic)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DDTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: DDTheme.radiusMedium)
                .strokeBorder(
                    (focusedField == .systolic || focusedField == .diastolic)
                        ? DDTheme.accent : DDTheme.cardBorder,
                    lineWidth: (focusedField == .systolic || focusedField == .diastolic) ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
    }

    // MARK: - Load / Save

    private func loadDraft() {
        let draft = VitalsDraft(vitals: vitals, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
        weightText = draft.weightText
        systolic = draft.systolic
        diastolic = draft.diastolic
        hr = draft.hr
        glucose = draft.glucose
    }

    private func persistIfNeeded() {
        let draft = VitalsDraft(
            weightText: weightText,
            systolic: systolic,
            diastolic: diastolic,
            hr: hr,
            glucose: glucose
        )

        if vitals == nil && draft.isEmpty { return }

        let target: DailyVitals
        if let existing = vitals {
            target = existing
        } else {
            target = DailyVitals(date: date)
            modelContext.insert(target)
        }

        target.date = Calendar.current.startOfDay(for: date)
        draft.apply(to: target, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
    }
}
