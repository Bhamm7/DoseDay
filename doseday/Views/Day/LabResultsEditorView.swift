import SwiftUI
import SwiftData

private let commonTests: [(name: String, unit: String)] = [
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

struct LabResultsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date
    @Query private var allResults: [LabResult]

    @State private var showingEntry = false
    @State private var editingResult: LabResult? = nil

    private var dayResults: [LabResult] {
        allResults
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.testName < $1.testName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Lab Results")
                    .font(.headline)
                Spacer()
                Button {
                    editingResult = nil
                    showingEntry = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if dayResults.isEmpty {
                Text("No lab results logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(dayResults) { result in
                    Button {
                        editingResult = result
                        showingEntry = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.testName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("\(result.value.formatted(.number.precision(.fractionLength(1)))) \(result.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if result.isOutOfRange {
                                Image(systemName: "flag.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel("Out of reference range")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading)
                }
            }
        }
        .sheet(isPresented: $showingEntry) {
            LabResultEntrySheet(date: date, result: editingResult) { newResult in
                if editingResult == nil {
                    modelContext.insert(newResult)
                } else {
                    editingResult?.testName = newResult.testName
                    editingResult?.value = newResult.value
                    editingResult?.unit = newResult.unit
                    editingResult?.referenceRangeLow = newResult.referenceRangeLow
                    editingResult?.referenceRangeHigh = newResult.referenceRangeHigh
                    editingResult?.notes = newResult.notes
                    editingResult?.updatedAt = Date()
                }
            }
        }
    }
}

// MARK: - Entry Sheet

private struct LabResultEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let result: LabResult?
    let onSave: (LabResult) -> Void

    @State private var selectedTestIndex: Int = 0
    @State private var isCustom = false
    @State private var customName = ""
    @State private var valueText = ""
    @State private var unit = ""
    @State private var refLowText = ""
    @State private var refHighText = ""
    @State private var notes = ""

    private var testName: String {
        isCustom ? customName : commonTests[selectedTestIndex].name
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Test") {
                    if !isCustom {
                        Picker("Test name", selection: $selectedTestIndex) {
                            ForEach(commonTests.indices, id: \.self) { i in
                                Text(commonTests[i].name).tag(i)
                            }
                        }
                        .onChange(of: selectedTestIndex) {
                            unit = commonTests[selectedTestIndex].unit
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
                            // Caller handles deletion by checking result != nil
                            onSave(buildResult())
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
                        onSave(buildResult())
                        dismiss()
                    }
                    .disabled(valueText.isEmpty || testName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { populateFromResult() }
        }
    }

    private func populateFromResult() {
        guard let r = result else {
            unit = commonTests[0].unit
            return
        }
        if let idx = commonTests.firstIndex(where: { $0.name == r.testName }) {
            selectedTestIndex = idx
            isCustom = false
        } else {
            isCustom = true
            customName = r.testName
        }
        valueText = r.value.formatted(.number.precision(.fractionLength(1)))
        unit = r.unit
        if let low = r.referenceRangeLow { refLowText = low.formatted(.number.precision(.fractionLength(1))) }
        if let high = r.referenceRangeHigh { refHighText = high.formatted(.number.precision(.fractionLength(1))) }
        notes = r.notes
    }

    private func buildResult() -> LabResult {
        LabResult(
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
