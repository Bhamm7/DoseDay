import SwiftUI
import SwiftData

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
            LabResultEditorSheet(date: editingResult?.date ?? date, result: editingResult) { action in
                switch action {
                case .save(let draft):
                    if let existing = editingResult {
                        existing.date = Calendar.current.startOfDay(for: draft.date)
                        existing.testName = draft.testName
                        existing.value = draft.value
                        existing.unit = draft.unit
                        existing.referenceRangeLow = draft.referenceRangeLow
                        existing.referenceRangeHigh = draft.referenceRangeHigh
                        existing.notes = draft.notes
                        existing.updatedAt = Date()
                    } else {
                        let result = LabResult(
                            date: draft.date,
                            testName: draft.testName,
                            value: draft.value,
                            unit: draft.unit,
                            referenceRangeLow: draft.referenceRangeLow,
                            referenceRangeHigh: draft.referenceRangeHigh,
                            notes: draft.notes
                        )
                        modelContext.insert(result)
                    }
                case .delete:
                    if let existing = editingResult {
                        modelContext.delete(existing)
                    }
                }
            }
        }
    }
}
