import SwiftUI

// MARK: - Zone definition

private struct BodyZone {
    let site: InjectionSite
    let isFront: Bool
    /// Normalized rect (0–1) within the body canvas
    let rect: CGRect
}

private let bodyZones: [BodyZone] = [
    BodyZone(site: .abdomenLeft,  isFront: true,  rect: CGRect(x: 0.30, y: 0.38, width: 0.18, height: 0.12)),
    BodyZone(site: .abdomenRight, isFront: true,  rect: CGRect(x: 0.52, y: 0.38, width: 0.18, height: 0.12)),
    BodyZone(site: .thighLeft,    isFront: true,  rect: CGRect(x: 0.28, y: 0.58, width: 0.16, height: 0.14)),
    BodyZone(site: .thighRight,   isFront: true,  rect: CGRect(x: 0.54, y: 0.58, width: 0.16, height: 0.14)),
    BodyZone(site: .upperArmLeft, isFront: true,  rect: CGRect(x: 0.16, y: 0.24, width: 0.12, height: 0.12)),
    BodyZone(site: .upperArmRight,isFront: true,  rect: CGRect(x: 0.70, y: 0.24, width: 0.12, height: 0.12)),
    BodyZone(site: .buttockLeft,  isFront: false, rect: CGRect(x: 0.28, y: 0.42, width: 0.18, height: 0.14)),
    BodyZone(site: .buttockRight, isFront: false, rect: CGRect(x: 0.52, y: 0.42, width: 0.18, height: 0.14)),
]

// MARK: - Heat color

private func heatColor(daysSinceLastInjection days: Int?) -> Color {
    guard let days else { return Color.secondary.opacity(0.15) }
    switch days {
    case 0...3:   return .red
    case 4...14:  return .orange
    case 15...30: return .yellow
    case 31...90: return .green
    default:      return Color.secondary.opacity(0.4)
    }
}

// MARK: - Body silhouette Canvas

private struct BodySilhouette: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Head
            let headR = w * 0.12
            let headCX = w * 0.5
            let headCY = h * 0.08
            ctx.fill(
                Path(ellipseIn: CGRect(x: headCX - headR, y: headCY - headR,
                                       width: headR * 2, height: headR * 2)),
                with: .color(.secondary.opacity(0.15))
            )
            var headStroke = Path(ellipseIn: CGRect(x: headCX - headR, y: headCY - headR,
                                                    width: headR * 2, height: headR * 2))
            ctx.stroke(headStroke, with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)

            // Torso
            let torsoX = w * 0.28
            let torsoY = h * 0.17
            let torsoW = w * 0.44
            let torsoH = h * 0.36
            var torso = Path(roundedRect: CGRect(x: torsoX, y: torsoY, width: torsoW, height: torsoH),
                             cornerRadius: 8)
            ctx.fill(torso, with: .color(.secondary.opacity(0.1)))
            ctx.stroke(torso, with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)

            // Arms
            let armW = w * 0.10
            let armH = h * 0.32
            let leftArmX = torsoX - armW + 2
            let rightArmX = torsoX + torsoW - 2
            let armY = torsoY + h * 0.01
            for armX in [leftArmX, rightArmX] {
                var arm = Path(roundedRect: CGRect(x: armX, y: armY, width: armW, height: armH),
                               cornerRadius: 6)
                ctx.fill(arm, with: .color(.secondary.opacity(0.1)))
                ctx.stroke(arm, with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)
            }

            // Legs
            let legW = w * 0.18
            let legH = h * 0.34
            let legY = torsoY + torsoH - 4
            let leftLegX = w * 0.28
            let rightLegX = w * 0.54
            for legX in [leftLegX, rightLegX] {
                var leg = Path(roundedRect: CGRect(x: legX, y: legY, width: legW, height: legH),
                               cornerRadius: 6)
                ctx.fill(leg, with: .color(.secondary.opacity(0.1)))
                ctx.stroke(leg, with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)
            }
        }
    }
}

// MARK: - BodyMapView

struct BodyMapView: View {
    // Picker mode: provide a binding
    var selectedSite: Binding<InjectionSite?>?
    // History mode: provide events
    var historyEvents: [DoseEvent] = []
    var isPickerMode: Bool

    @State private var showingBack = false

    private var visibleZones: [BodyZone] {
        bodyZones.filter { $0.isFront != showingBack }
    }

    /// Most recent injection date per site (for history heat map)
    private func daysSinceLast(for site: InjectionSite) -> Int? {
        let now = Date()
        let matching = historyEvents.compactMap { event -> Date? in
            guard event.resolvedInjectionSite == site,
                  event.status == .taken,
                  let takenAt = event.takenAt else { return nil }
            return takenAt
        }
        guard let latest = matching.max() else { return nil }
        return Calendar.current.dateComponents([.day], from: latest, to: now).day
    }

    /// Count of injections per site (for history mode dot sizing)
    private func count(for site: InjectionSite) -> Int {
        historyEvents.filter { $0.resolvedInjectionSite == site && $0.status == .taken }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Front / Back toggle
            Picker("View", selection: $showingBack) {
                Text("Front").tag(false)
                Text("Back").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Body diagram with tappable zones
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    BodySilhouette()

                    ForEach(visibleZones, id: \.site.rawValue) { zone in
                        let rect = denormalized(zone.rect, in: size)
                        zoneView(zone: zone, rect: rect)
                    }
                }
            }
            .aspectRatio(0.55, contentMode: .fit)
            .padding(.horizontal)

            if !isPickerMode {
                heatLegend
            }
        }
    }

    @ViewBuilder
    private func zoneView(zone: BodyZone, rect: CGRect) -> some View {
        let isSelected = selectedSite?.wrappedValue == zone.site
        let days = isPickerMode ? nil : daysSinceLast(for: zone.site)
        let color: Color = isPickerMode
            ? (isSelected ? .blue : Color.secondary.opacity(0.25))
            : heatColor(daysSinceLastInjection: days)
        let hasHistory = !isPickerMode && daysSinceLast(for: zone.site) != nil

        Button {
            if isPickerMode {
                selectedSite?.wrappedValue = zone.site
            }
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(isPickerMode ? 0.4 : (hasHistory ? 0.55 : 0.15)))
                .overlay {
                    if isPickerMode && isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.blue, lineWidth: 2)
                    }
                    if !isPickerMode && hasHistory {
                        Text("\(count(for: zone.site))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .accessibilityLabel(zone.site.displayName)
        .accessibilityAddTraits(isPickerMode && isSelected ? .isSelected : [])
        .disabled(!isPickerMode)
    }

    private var heatLegend: some View {
        HStack(spacing: 12) {
            ForEach([
                ("0–3d", Color.red),
                ("4–14d", Color.orange),
                ("15–30d", Color.yellow),
                ("31–90d", Color.green),
                ("90d+", Color.secondary),
            ], id: \.0) { label, color in
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func denormalized(_ norm: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: norm.minX * size.width,
            y: norm.minY * size.height,
            width: norm.width * size.width,
            height: norm.height * size.height
        )
    }
}
