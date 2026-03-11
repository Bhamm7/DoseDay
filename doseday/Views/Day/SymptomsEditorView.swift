import SwiftUI
import SwiftData

struct SymptomsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date
    @Query(sort: \SymptomTag.sortOrder) private var allTags: [SymptomTag]
    @Query private var allSymptoms: [DailySymptom]

    private var daySymptoms: [DailySymptom] {
        allSymptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func symptom(for tag: SymptomTag) -> DailySymptom? {
        daySymptoms.first { $0.tag?.id == tag.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptoms")
                .font(.headline)
                .padding(.horizontal)

            if allTags.isEmpty {
                Text("No symptom tags — add them in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(allTags) { tag in
                        SymptomChip(
                            tag: tag,
                            symptom: symptom(for: tag),
                            onTap: { handleTap(tag: tag) }
                        )
                    }
                }
                .padding(.horizontal)
            }
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
}

// MARK: - Chip

private struct SymptomChip: View {
    let tag: SymptomTag
    let symptom: DailySymptom?
    let onTap: () -> Void

    private var isActive: Bool { symptom != nil }
    private var severityLabel: String? {
        guard let s = symptom else { return nil }
        switch s.severity {
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Severe"
        default: return nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.caption.weight(.medium))
                if let label = severityLabel {
                    Text("· \(label)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? Color(hex: tag.colorHex).opacity(0.15) : Color.secondary.opacity(0.1))
            .overlay {
                Capsule().strokeBorder(isActive ? Color(hex: tag.colorHex) : Color.clear, lineWidth: 1.5)
            }
            .clipShape(Capsule())
            .foregroundStyle(isActive ? Color(hex: tag.colorHex) : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tag.name)
        .accessibilityValue(severityLabel ?? "Off")
        .accessibilityHint("Tap to cycle: mild, moderate, severe, off")
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

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
