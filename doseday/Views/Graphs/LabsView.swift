import SwiftUI
import SwiftData

struct LabsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LabReport.collectedAt, order: .reverse) private var reports: [LabReport]
    @Query(sort: \LabResult.date, order: .reverse) private var allResults: [LabResult]

    @State private var showAddReport = false
    @State private var selectedReport: LabReport?
    @State private var showImportPlaceholder = false

    private var standaloneResults: [LabResult] {
        allResults
            .filter { $0.report == nil }
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.testName < $1.testName
            }
    }

    var body: some View {
        Group {
            if reports.isEmpty && standaloneResults.isEmpty {
                ContentUnavailableView(
                    "No Labs Yet",
                    systemImage: "testtube.2",
                    description: Text("Create a report or add a result from a day to start building your lab history.")
                )
            } else {
                List {
                    if !reports.isEmpty {
                        Section("Reports") {
                            ForEach(reports) { report in
                                Button {
                                    selectedReport = report
                                } label: {
                                    LabReportRow(report: report)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    modelContext.delete(reports[index])
                                }
                            }
                        }
                    }

                    if !standaloneResults.isEmpty {
                        Section("Standalone Results") {
                            ForEach(standaloneResults) { result in
                                StandaloneLabResultRow(result: result)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Report") {
                        showAddReport = true
                    }
                    Button("Import Report") {
                        showImportPlaceholder = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddReport) {
            LabReportEditorSheet { draft in
                let report = LabReport(
                    collectedAt: draft.collectedAt,
                    sourceName: draft.sourceName.isEmpty ? nil : draft.sourceName,
                    sourceType: draft.sourceType,
                    reportTitle: draft.reportTitle.isEmpty ? nil : draft.reportTitle,
                    notes: draft.notes
                )
                modelContext.insert(report)
            }
        }
        .navigationDestination(item: $selectedReport) { report in
            LabReportDetailView(report: report)
        }
        .alert("Import Not Implemented Yet", isPresented: $showImportPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The report upload flow is still a placeholder. The new report browser and report-backed lab model are in place.")
        }
    }
}

private struct LabReportRow: View {
    let report: LabReport

    private var sortedResults: [LabResult] {
        report.results.sorted { $0.testName < $1.testName }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(report.collectedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(summaryText(sortedResults))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if report.abnormalResultsCount > 0 {
                Text("\(report.abnormalResultsCount) flagged")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14), in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func summaryText(_ results: [LabResult]) -> String {
        let testCount = results.count
        if let sourceName = report.sourceName, !sourceName.isEmpty {
            return "\(sourceName) • \(testCount) marker\(testCount == 1 ? "" : "s")"
        }
        return "\(testCount) marker\(testCount == 1 ? "" : "s")"
    }
}

private struct StandaloneLabResultRow: View {
    let result: LabResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.subheadline.weight(.semibold))
                Text("\(result.value.formatted(.number.precision(.fractionLength(1)))) \(result.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(result.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption)
                .foregroundStyle(.secondary)
            if result.isOutOfRange {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct LabReportDraft {
    var collectedAt: Date
    var sourceName: String
    var sourceType: LabSourceType
    var reportTitle: String
    var notes: String
}

private struct LabReportEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let report: LabReport?
    let onSave: (LabReportDraft) -> Void

    @State private var collectedAt = Date()
    @State private var sourceName = ""
    @State private var sourceType: LabSourceType = .manual
    @State private var reportTitle = ""
    @State private var notes = ""

    init(report: LabReport? = nil, onSave: @escaping (LabReportDraft) -> Void) {
        self.report = report
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Report") {
                    TextField("Report Title", text: $reportTitle)
                    TextField("Source", text: $sourceName)
                    Picker("Source Type", selection: $sourceType) {
                        ForEach(LabSourceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    DatePicker("Collected", selection: $collectedAt, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(report == nil ? "New Report" : "Edit Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            LabReportDraft(
                                collectedAt: collectedAt,
                                sourceName: sourceName,
                                sourceType: sourceType,
                                reportTitle: reportTitle,
                                notes: notes
                            )
                        )
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                guard let report else { return }
                collectedAt = report.collectedAt
                sourceName = report.sourceName ?? ""
                sourceType = report.sourceType
                reportTitle = report.reportTitle ?? ""
                notes = report.notes
            }
        }
    }
}

private struct LabReportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var report: LabReport

    @State private var showEditReport = false
    @State private var showAddResult = false
    @State private var editingResult: LabResult?

    private var sortedResults: [LabResult] {
        report.results.sorted {
            if $0.testName != $1.testName { return $0.testName < $1.testName }
            return $0.date > $1.date
        }
    }

    var body: some View {
        List {
            Section("Report Info") {
                LabeledContent("Collected") {
                    Text(report.collectedAt, format: .dateTime.month(.wide).day().year().hour().minute())
                }
                if let sourceName = report.sourceName, !sourceName.isEmpty {
                    LabeledContent("Source", value: sourceName)
                }
                LabeledContent("Type", value: report.sourceType.displayName)
                if !report.notes.isEmpty {
                    Text(report.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Markers") {
                if sortedResults.isEmpty {
                    Text("No markers added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedResults) { result in
                        Button {
                            editingResult = result
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.testName)
                                        .font(.body.weight(.semibold))
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
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(sortedResults[index])
                        }
                    }
                }

                Button {
                    showAddResult = true
                } label: {
                    Label("Add Marker", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(report.displayTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditReport = true
                }
            }
        }
        .sheet(isPresented: $showEditReport) {
            LabReportEditorSheet(report: report) { draft in
                report.collectedAt = draft.collectedAt
                report.sourceName = draft.sourceName.isEmpty ? nil : draft.sourceName
                report.sourceType = draft.sourceType
                report.reportTitle = draft.reportTitle.isEmpty ? nil : draft.reportTitle
                report.notes = draft.notes
                report.updatedAt = Date()
            }
        }
        .sheet(isPresented: $showAddResult) {
            LabResultEditorSheet(date: report.collectedAt, result: nil) { action in
                guard case .save(let draft) = action else { return }
                let result = LabResult(
                    date: draft.date,
                    testName: draft.testName,
                    value: draft.value,
                    unit: draft.unit,
                    referenceRangeLow: draft.referenceRangeLow,
                    referenceRangeHigh: draft.referenceRangeHigh,
                    notes: draft.notes,
                    report: report
                )
                modelContext.insert(result)
                report.updatedAt = Date()
            }
        }
        .sheet(item: $editingResult) { result in
            LabResultEditorSheet(date: result.date, result: result) { action in
                switch action {
                case .save(let draft):
                    result.date = Calendar.current.startOfDay(for: draft.date)
                    result.testName = draft.testName
                    result.value = draft.value
                    result.unit = draft.unit
                    result.referenceRangeLow = draft.referenceRangeLow
                    result.referenceRangeHigh = draft.referenceRangeHigh
                    result.notes = draft.notes
                    result.updatedAt = Date()
                    report.updatedAt = Date()
                case .delete:
                    modelContext.delete(result)
                    report.updatedAt = Date()
                }
            }
        }
    }
}
