import SwiftUI

let commonLabTests: [(name: String, unit: String)] = [
    ("Total Testosterone", "ng/dL"),
    ("Free Testosterone",  "pg/mL"),
    ("Estradiol",          "pg/mL"),
    ("LH",                 "mIU/mL"),
    ("FSH",                "mIU/mL"),
    ("Hematocrit",         "%"),
    ("Hemoglobin",         "g/dL"),
    ("SHBG",               "nmol/L"),
    ("PSA",                "ng/mL"),
    ("TSH",                "mIU/L"),
    ("Cortisol",           "mcg/dL"),
]

struct LabResultDraft {
    var date: Date
    var testName: String
    var value: Double
    var unit: String
    var referenceRangeLow: Double?
    var referenceRangeHigh: Double?
    var notes: String
}

enum LabResultEditorAction {
    case save(LabResultDraft)
    case delete
}

struct LabResultEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let result: LabResult?
    let onAction: (LabResultEditorAction) -> Void

    @State private var selectedTestIndex = 0
    @State private var isCustom = false
    @State private var customName = ""
    @State private var valueText = ""
    @State private var unit = ""
    @State private var refLowText = ""
    @State private var refHighText = ""
    @State private var notes = ""

    private var testName: String {
        isCustom ? customName : commonLabTests[selectedTestIndex].name
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Test") {
                    if !isCustom {
                        Picker("Test name", selection: $selectedTestIndex) {
                            ForEach(commonLabTests.indices, id: \.self) { index in
                                Text(commonLabTests[index].name).tag(index)
                            }
                        }
                        .onChange(of: selectedTestIndex) { _, newIndex in
                            unit = commonLabTests[newIndex].unit
                        }
                    }
                    Toggle("Custom test name", isOn: $isCustom)
                    if isCustom {
                        TextField("Test name", text: $customName)
                    }
                }

                Section("Result") {
                    HStack {
                        TextField("Value", text: $valueText)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $unit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reference Range (optional)") {
                    HStack {
                        TextField("Low", text: $refLowText)
                            .keyboardType(.decimalPad)
                        Text("–")
                        TextField("High", text: $refHighText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if result != nil {
                    Section {
                        Button("Delete", role: .destructive) {
                            onAction(.delete)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(result == nil ? "Add Lab Result" : "Edit Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onAction(.save(buildDraft()))
                        dismiss()
                    }
                    .disabled(valueText.isEmpty || testName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: populateFromResult)
        }
    }

    private func populateFromResult() {
        guard let result else {
            unit = commonLabTests[0].unit
            return
        }

        if let index = commonLabTests.firstIndex(where: { $0.name == result.testName }) {
            selectedTestIndex = index
            isCustom = false
        } else {
            isCustom = true
            customName = result.testName
        }

        valueText = result.value.formatted(.number.precision(.fractionLength(1)))
        unit = result.unit
        if let low = result.referenceRangeLow {
            refLowText = low.formatted(.number.precision(.fractionLength(1)))
        }
        if let high = result.referenceRangeHigh {
            refHighText = high.formatted(.number.precision(.fractionLength(1)))
        }
        notes = result.notes
    }

    private func buildDraft() -> LabResultDraft {
        LabResultDraft(
            date: date,
            testName: testName,
            value: Double(valueText) ?? 0,
            unit: unit,
            referenceRangeLow: Double(refLowText),
            referenceRangeHigh: Double(refHighText),
            notes: notes
        )
    }
}
