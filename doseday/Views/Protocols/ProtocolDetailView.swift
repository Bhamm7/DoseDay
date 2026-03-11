import SwiftUI
import SwiftData

struct ProtocolDetailView: View {
    @Bindable var proto: MedicationProtocol
    @Environment(\.modelContext) private var modelContext

    @State private var showAddDrug = false
    @State private var showEndProtocol = false
    @State private var editingDrug: Drug?

    var body: some View {
        List {
            Section("Protocol Info") {
                LabeledContent("Start Date") {
                    Text(proto.startDate, format: .dateTime.month(.wide).day().year())
                }
                if let end = proto.endDate {
                    LabeledContent("End Date") {
                        Text(end, format: .dateTime.month(.wide).day().year())
                    }
                }
                if !proto.notes.isEmpty {
                    Text(proto.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if proto.drugs.isEmpty {
                    Text("No drugs added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(proto.drugs) { drug in
                        Button {
                            editingDrug = drug
                        } label: {
                            DrugRowSummary(drug: drug)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(proto.drugs[index])
                        }
                    }
                }

                Button {
                    showAddDrug = true
                } label: {
                    Label("Add Drug", systemImage: "plus.circle")
                }
            } header: {
                Text("Drugs")
            }

            if proto.endDate == nil {
                Section {
                    Button(role: .destructive) {
                        showEndProtocol = true
                    } label: {
                        Label("End Protocol", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .navigationTitle(proto.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddDrug) {
            DrugEditorView(protocol: proto)
        }
        .sheet(item: $editingDrug) { drug in
            DrugEditorView(protocol: proto, existingDrug: drug)
        }
        .confirmationDialog("End Protocol", isPresented: $showEndProtocol, titleVisibility: .visible) {
            Button("End Today", role: .destructive) {
                proto.endDate = Calendar.current.startOfDay(for: Date())
                proto.updatedAt = Date()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will set the protocol end date to today.")
        }
    }
}

private struct DrugRowSummary: View {
    let drug: Drug

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: drug.colorHex))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(drug.name)
                    .font(.body)

                Text(scheduleSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var scheduleSummary: String {
        guard let sched = drug.schedule else { return "No schedule" }
        let times = sched.times.map { $0.formatted }.joined(separator: ", ")
        switch sched.frequencyType {
        case .daily:
            return "Daily at \(times)"
        case .specificDays:
            let days = (sched.weekdays ?? []).compactMap { weekdayName($0) }.joined(separator: ", ")
            return "\(days) at \(times)"
        case .everyNDays:
            let n = sched.intervalDays ?? 1
            return "Every \(n) days at \(times)"
        }
    }

    private func weekdayName(_ weekday: Int) -> String? {
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return Calendar.current.shortWeekdaySymbols[weekday - 1]
    }
}
