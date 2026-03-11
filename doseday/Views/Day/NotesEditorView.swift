import SwiftUI
import SwiftData

struct NotesEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date
    let note: DailyNote?

    @State private var sideEffects: String = ""
    @State private var observations: String = ""
    @State private var savedAt: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                if let savedAt {
                    Text("Saved at \(savedAt.formatted(.dateTime.hour().minute()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Side Effects")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Any side effects today?", text: $sideEffects, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(8)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Observations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("General observations…", text: $observations, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(8)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button("Save Notes") {
                saveNotes()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .onAppear { loadNotes() }
    }

    private func loadNotes() {
        guard let n = note else { return }
        sideEffects = n.sideEffects
        observations = n.observations
    }

    private func saveNotes() {
        let target: DailyNote
        if let existing = note {
            target = existing
        } else {
            target = DailyNote(date: date)
            modelContext.insert(target)
        }
        target.sideEffects = sideEffects
        target.observations = observations
        target.updatedAt = Date()
        savedAt = Date()
    }
}
