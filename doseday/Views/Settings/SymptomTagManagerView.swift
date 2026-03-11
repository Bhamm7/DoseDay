import SwiftUI
import SwiftData

struct SymptomTagManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomTag.sortOrder) private var allTags: [SymptomTag]

    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newColorHex = "#007AFF"

    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue",   "#007AFF"), ("Green",  "#34C759"), ("Red",    "#FF3B30"),
        ("Orange", "#FF9500"), ("Purple", "#AF52DE"), ("Pink",   "#FF2D55"),
        ("Teal",   "#5AC8FA"), ("Yellow", "#FFCC00"),
    ]

    var body: some View {
        List {
            Section("System Tags") {
                ForEach(allTags.filter(\.isSystem)) { tag in
                    tagRow(tag)
                }
            }
            Section("Custom Tags") {
                ForEach(allTags.filter { !$0.isSystem }) { tag in
                    tagRow(tag)
                }
                .onDelete { offsets in
                    let custom = allTags.filter { !$0.isSystem }
                    for i in offsets { modelContext.delete(custom[i]) }
                }
            }
        }
        .navigationTitle("Symptom Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            addSheet
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: SymptomTag) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 14, height: 14)
            Text(tag.name)
            if tag.isSystem {
                Spacer()
                Text("System")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Cramps", text: $newName)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colorOptions, id: \.hex) { option in
                            Button {
                                newColorHex = option.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: option.hex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if newColorHex == option.hex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.caption.weight(.bold))
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.name)
                            .accessibilityAddTraits(newColorHex == option.hex ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let maxOrder = allTags.map(\.sortOrder).max() ?? -1
                        let tag = SymptomTag(name: newName.trimmingCharacters(in: .whitespaces),
                                             colorHex: newColorHex,
                                             isSystem: false,
                                             sortOrder: maxOrder + 1)
                        modelContext.insert(tag)
                        newName = ""
                        newColorHex = "#007AFF"
                        showingAdd = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAdd = false }
                }
            }
        }
    }
}
