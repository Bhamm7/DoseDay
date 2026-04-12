import SwiftUI

struct DayCellView: View {
    let date: Date
    let events: [DoseEvent]
    let isToday: Bool
    let isSelected: Bool

    private var uniqueDrugs: [Drug] {
        var seen = Set<UUID>()
        return events.compactMap { event -> Drug? in
            guard let drug = event.drug, seen.insert(drug.id).inserted else { return nil }
            return drug
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isToday ? DDTheme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))
                .overlay {
                    if isSelected && !isToday {
                        RoundedRectangle(cornerRadius: DDTheme.radiusMedium).strokeBorder(DDTheme.accent, lineWidth: 1.5)
                    }
                }

            if !uniqueDrugs.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(uniqueDrugs.prefix(3)), id: \.id) { drug in
                        Circle()
                            .fill(Color(hex: drug.colorHex))
                            .frame(width: 6, height: 6)
                    }
                    if uniqueDrugs.count > 3 {
                        Text("+\(uniqueDrugs.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 10)
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Selects day")
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        let dayStr = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        switch events.count {
        case 0: return dayStr
        case 1: return "\(dayStr), 1 dose"
        default: return "\(dayStr), \(events.count) doses"
        }
    }
}
