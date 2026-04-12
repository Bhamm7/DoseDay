import SwiftUI
import SwiftData

// MARK: - Unified Notes & Symptoms section for ScheduleView

struct NotesSymptomsSectionView: View {
    @Environment(\.modelContext) private var modelContext

    let date: Date
    let note: DailyNote?
    let daySymptoms: [DailySymptom]
    let onAddSymptom: () -> Void

    @State private var sideEffects = ""
    @State private var observations = ""
    @FocusState private var focusedField: NoteField?

    private enum NoteField: Hashable { case sideEffects, observations }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Symptoms row
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.clipboard")
                            .font(.caption)
                            .foregroundStyle(DDTheme.accent)
                        Text("Symptoms")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DDTheme.textPrimary)
                    }

                    if daySymptoms.isEmpty {
                        Text("None logged")
                            .font(.caption)
                            .foregroundStyle(DDTheme.textTertiary)
                    } else {
                        // Compact chips for active symptoms
                        FlowLayoutCompact(spacing: 6) {
                            ForEach(daySymptoms) { symptom in
                                if let tag = symptom.tag {
                                    activeChip(tag: tag, severity: symptom.severity) {
                                        removeSymptom(symptom)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Add button
                Button(action: onAddSymptom) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DDTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(DDTheme.accentTint)
                        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DDTheme.radiusMedium)
                                .strokeBorder(DDTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .foregroundStyle(DDTheme.divider)

            // Notes fields
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(DDTheme.accent)
                    Text("Notes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DDTheme.textPrimary)
                }

                TextField("Side effects…", text: $sideEffects, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...3)
                    .padding(8)
                    .background(DDTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DDTheme.radiusMedium)
                            .strokeBorder(
                                focusedField == .sideEffects ? DDTheme.accent : DDTheme.cardBorder,
                                lineWidth: focusedField == .sideEffects ? 1.5 : 1
                            )
                    )
                    .focused($focusedField, equals: .sideEffects)

                TextField("Observations…", text: $observations, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...3)
                    .padding(8)
                    .background(DDTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DDTheme.radiusMedium)
                            .strokeBorder(
                                focusedField == .observations ? DDTheme.accent : DDTheme.cardBorder,
                                lineWidth: focusedField == .observations ? 1.5 : 1
                            )
                    )
                    .focused($focusedField, equals: .observations)
            }
        }
        .onAppear { loadNotes() }
        .onChange(of: date) { _, _ in loadNotes() }
        .onChange(of: note?.id) { _, _ in loadNotes() }
        .onChange(of: focusedField) { old, new in
            if old != nil && new == nil { saveNotes() }
        }
        .onDisappear { saveNotes() }
    }

    // MARK: - Active symptom chip

    private func activeChip(tag: SymptomTag, severity: Int, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 6, height: 6)
            Text(tag.name)
                .font(.caption2.weight(.medium))
            if severity > 1 {
                Text("·")
                    .font(.caption2)
                Text(severityLabel(severity))
                    .font(.caption2)
                    .foregroundStyle(DDTheme.textTertiary)
            }
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DDTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: tag.colorHex).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusSmall))
    }

    private func severityLabel(_ severity: Int) -> String {
        switch severity {
        case 1: "Mild"
        case 2: "Mod"
        case 3: "Severe"
        default: ""
        }
    }

    private func removeSymptom(_ symptom: DailySymptom) {
        modelContext.delete(symptom)
    }

    // MARK: - Notes persistence

    private func loadNotes() {
        guard let n = note else {
            sideEffects = ""
            observations = ""
            return
        }
        sideEffects = n.sideEffects
        observations = n.observations
    }

    private func saveNotes() {
        let trimmedSide = sideEffects.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedObs = observations.trimmingCharacters(in: .whitespacesAndNewlines)

        if note == nil && trimmedSide.isEmpty && trimmedObs.isEmpty { return }

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
    }
}

// MARK: - Symptom Picker Sheet

struct SymptomPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @Query(sort: \SymptomTag.sortOrder) private var allTags: [SymptomTag]
    @Query private var allSymptoms: [DailySymptom]

    @State private var showAddTag = false
    @State private var newTagName = ""
    @State private var newTagColor = "#FF9500"

    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue",   "#007AFF"), ("Green",  "#34C759"), ("Red",    "#FF3B30"),
        ("Orange", "#FF9500"), ("Purple", "#AF52DE"), ("Pink",   "#FF2D55"),
        ("Teal",   "#5AC8FA"), ("Yellow", "#FFCC00"),
    ]

    private var daySymptoms: [DailySymptom] {
        allSymptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func symptom(for tag: SymptomTag) -> DailySymptom? {
        daySymptoms.first { $0.tag?.id == tag.id }
    }

    var body: some View {
        NavigationStack {
            List {
                if allTags.isEmpty {
                    Text("No symptom tags yet — add one below.")
                        .font(.subheadline)
                        .foregroundStyle(DDTheme.textTertiary)
                }

                ForEach(allTags) { tag in
                    let existing = symptom(for: tag)
                    let isActive = existing != nil

                    Button {
                        handleTap(tag: tag)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 10, height: 10)

                            Text(tag.name)
                                .font(.subheadline)
                                .foregroundStyle(DDTheme.textPrimary)

                            Spacer()

                            if let s = existing {
                                Text(severityLabel(s.severity))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(hex: tag.colorHex))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: tag.colorHex).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusSmall))
                            }

                            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isActive ? DDTheme.accent : DDTheme.textTertiary)
                                .font(.title3)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Add new tag inline
                if showAddTag {
                    addTagSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Log Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        withAnimation { showAddTag.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Symptom Tag")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DDTheme.accent)
                    }
                }
            }
        }
    }

    private var addTagSection: some View {
        Section("New Tag") {
            TextField("Symptom name", text: $newTagName)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(colorOptions, id: \.hex) { option in
                    Button {
                        newTagColor = option.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if newTagColor == option.hex {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                        .font(.caption2.weight(.bold))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            Button("Add Tag") {
                guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let maxOrder = allTags.map(\.sortOrder).max() ?? -1
                let tag = SymptomTag(
                    name: newTagName.trimmingCharacters(in: .whitespaces),
                    colorHex: newTagColor,
                    isSystem: false,
                    sortOrder: maxOrder + 1
                )
                modelContext.insert(tag)
                newTagName = ""
                newTagColor = "#FF9500"
                withAnimation { showAddTag = false }
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func handleTap(tag: SymptomTag) {
        if let existing = symptom(for: tag) {
            if existing.severity < 3 {
                existing.severity += 1
            } else {
                modelContext.delete(existing)
            }
        } else {
            let s = DailySymptom(date: date, tag: tag, severity: 1)
            modelContext.insert(s)
        }
    }

    private func severityLabel(_ severity: Int) -> String {
        switch severity {
        case 1: "Mild"
        case 2: "Moderate"
        case 3: "Severe"
        default: ""
        }
    }
}

// MARK: - Compact FlowLayout (reusable)

struct FlowLayoutCompact: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if x + w > maxWidth && !rows.last!.isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(view)
            x += w + spacing
        }
        return rows
    }
}
