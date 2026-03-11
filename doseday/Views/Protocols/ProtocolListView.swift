import SwiftUI
import SwiftData

struct ProtocolListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MedicationProtocol.startDate, order: .reverse)
    private var protocols: [MedicationProtocol]

    @State private var showAddProtocol = false
    @State private var selectedProtocol: MedicationProtocol?

    var body: some View {
        Group {
            if protocols.isEmpty {
                ContentUnavailableView(
                    "No Protocols",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Add a protocol to start tracking your medications.")
                )
            } else {
                List {
                    ForEach(protocols) { proto in
                        Button {
                            selectedProtocol = proto
                        } label: {
                            ProtocolRowView(proto: proto)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(protocols[index])
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Protocols")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddProtocol = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddProtocol) {
            AddProtocolFlow()
        }
        .navigationDestination(item: $selectedProtocol) { proto in
            ProtocolDetailView(proto: proto)
        }
    }
}

private struct ProtocolRowView: View {
    let proto: MedicationProtocol

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: proto.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(proto.name)
                    .font(.body.weight(.medium))

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !proto.drugs.isEmpty {
                    Text("\(proto.drugs.count) drug\(proto.drugs.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dateRangeText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        let start = f.string(from: proto.startDate)
        if let end = proto.endDate {
            return "\(start) – \(f.string(from: end))"
        }
        return "Started \(start)"
    }
}
