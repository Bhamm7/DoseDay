import SwiftUI
import RealityKit
import BodyModel

fileprivate struct BodyHistoryOverlayMarker: Identifiable, Equatable {
    let id: UUID
    let screenPoint: CGPoint
    let title: String
    let subtitle: String
    let prefersLeadingSide: Bool
}

// MARK: - BodyMapView (SwiftUI shell)

struct BodyMapView: View {
    var selectedSite: Binding<InjectionSite?>?
    var historyEvents: [DoseEvent] = []
    var showsHistory: Bool = false
    var isPickerMode: Bool
    var onSiteTapped: ((InjectionSite, SIMD3<Float>) -> Void)? = nil
    @State private var showsHistoryCallouts = true
    @State private var projectedHistoryMarkers: [BodyHistoryOverlayMarker] = []

    private var shouldShowHistory: Bool {
        showsHistory || !isPickerMode
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                BodyARViewRepresentable(
                    selectedSite: selectedSite,
                    historyEvents: historyEvents,
                    projectedHistoryMarkers: $projectedHistoryMarkers,
                    showsHistory: shouldShowHistory && showsHistoryCallouts,
                    showsHistoryCallouts: showsHistoryCallouts,
                    isPickerMode: isPickerMode,
                    onSiteTapped: onSiteTapped
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .layoutPriority(1)

                if shouldShowHistory && showsHistoryCallouts {
                    BodyHistoryCalloutOverlay(markers: projectedHistoryMarkers)
                        .allowsHitTesting(false)
                }

                if shouldShowHistory, !historyEvents.isEmpty {
                    Button {
                        showsHistoryCallouts.toggle()
                    } label: {
                        Image(systemName: showsHistoryCallouts ? "eye.slash" : "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .accessibilityLabel(showsHistoryCallouts ? "Hide history labels" : "Show history labels")
                }
            }

            if isPickerMode, let site = selectedSite?.wrappedValue {
                Text(site.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            if shouldShowHistory && showsHistoryCallouts {
                heatLegend
            }

            Text("2-finger drag to rotate · pinch to zoom")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var heatLegend: some View {
        HStack(spacing: 12) {
            ForEach([
                ("<2d",   Color.red),
                ("2–3d",  Color(red: 1.0, green: 0.27, blue: 0.0)),
                ("3–4d",  Color(red: 1.0, green: 0.6,  blue: 0.0)),
                ("4–10d", Color.yellow),
            ], id: \.0) { label, color in
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct BodyHistoryCalloutOverlay: View {
    let markers: [BodyHistoryOverlayMarker]

    private let bubbleSize = CGSize(width: 124, height: 48)
    private let horizontalMargin: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(markers) { marker in
                    let layout = layout(for: marker, in: proxy.size)

                    Path { path in
                        path.move(to: marker.screenPoint)
                        path.addLine(to: layout.connectorPoint)
                    }
                    .stroke(Color.white.opacity(0.34), lineWidth: 1.2)

                    VStack(spacing: 2) {
                        Text(marker.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(marker.subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .frame(width: bubbleSize.width, height: bubbleSize.height)
                    .background(Color.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    }
                    .position(layout.bubbleCenter)
                }
            }
        }
    }

    private func layout(for marker: BodyHistoryOverlayMarker, in size: CGSize) -> (bubbleCenter: CGPoint, connectorPoint: CGPoint) {
        let bubbleHalfWidth = bubbleSize.width / 2
        let bubbleHalfHeight = bubbleSize.height / 2
        let bubbleCenterX = marker.prefersLeadingSide
            ? horizontalMargin + bubbleHalfWidth
            : size.width - horizontalMargin - bubbleHalfWidth
        let bubbleCenterY = min(
            max(marker.screenPoint.y - 8, bubbleHalfHeight + 8),
            size.height - bubbleHalfHeight - 8
        )
        let connectorX = marker.prefersLeadingSide
            ? bubbleCenterX + bubbleHalfWidth - 6
            : bubbleCenterX - bubbleHalfWidth + 6

        return (
            bubbleCenter: CGPoint(x: bubbleCenterX, y: bubbleCenterY),
            connectorPoint: CGPoint(x: connectorX, y: bubbleCenterY)
        )
    }
}

// MARK: - UIViewRepresentable

struct BodyARViewRepresentable: UIViewRepresentable {
    var selectedSite: Binding<InjectionSite?>?
    var historyEvents: [DoseEvent]
    fileprivate var projectedHistoryMarkers: Binding<[BodyHistoryOverlayMarker]>
    var showsHistory: Bool
    var showsHistoryCallouts: Bool
    var isPickerMode: Bool
    var onSiteTapped: ((InjectionSite, SIMD3<Float>) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(.systemBackground)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.numberOfTouchesRequired = 1

        let rotate = UIPanGestureRecognizer(target: context.coordinator,
                                            action: #selector(Coordinator.handleRotation(_:)))
        rotate.minimumNumberOfTouches = 2
        rotate.maximumNumberOfTouches = 2

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))

        // Tap should not conflict with two-finger gestures
        rotate.require(toFail: tap)
        arView.addGestureRecognizer(tap)
        arView.addGestureRecognizer(rotate)
        arView.addGestureRecognizer(pinch)

        context.coordinator.arView        = arView
        context.coordinator.selectedSite  = selectedSite
        context.coordinator.isPickerMode  = isPickerMode
        context.coordinator.historyEvents = historyEvents
        context.coordinator.projectedHistoryMarkers = projectedHistoryMarkers
        context.coordinator.showsHistory  = showsHistory
        context.coordinator.showsHistoryCallouts = showsHistoryCallouts
        context.coordinator.onSiteTapped  = onSiteTapped

        Task { await context.coordinator.loadScene() }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selectedSite  = selectedSite
        context.coordinator.isPickerMode  = isPickerMode
        context.coordinator.onSiteTapped  = onSiteTapped
        context.coordinator.historyEvents = historyEvents
        context.coordinator.projectedHistoryMarkers = projectedHistoryMarkers
        context.coordinator.showsHistory  = showsHistory
        context.coordinator.showsHistoryCallouts = showsHistoryCallouts
        if showsHistory, let root = context.coordinator.sceneRoot {
            context.coordinator.refreshHistoryMarkers(in: root)
            context.coordinator.publishProjectedHistoryMarkers()
        } else if let root = context.coordinator.sceneRoot {
            root.findEntity(named: "__historyMarkers")?.removeFromParent()
            context.coordinator.projectedHistoryMarkers?.wrappedValue = []
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        private struct HistoryMarkerInfo {
            let id: UUID
            let position: SIMD3<Float>
            let color: UIColor
            let title: String
            let subtitle: String
        }

        weak var arView: ARView?
        var sceneRoot: Entity?
        var selectedSite: Binding<InjectionSite?>?
        var isPickerMode  = false
        var showsHistory = false
        var showsHistoryCallouts = true
        var historyEvents: [DoseEvent] = []
        fileprivate var projectedHistoryMarkers: Binding<[BodyHistoryOverlayMarker]>?
        var onSiteTapped: ((InjectionSite, SIMD3<Float>) -> Void)?
        var baseRotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
        var baseScale:    Float     = 4.0

        // MARK: Scene loading

        func loadScene() async {
            guard let arView,
                  let scene = try? await Entity(named: "Scene", in: bodyModelBundle) else { return }

            scene.position = [0, -2.5, -2.0]
            scene.scale = [baseScale, baseScale, baseScale]

            applyCyanGlow(to: scene)
            makeZonesInvisible(in: scene)

            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(scene)
            await MainActor.run {
                arView.scene.addAnchor(anchor)
                sceneRoot = scene
                if showsHistory {
                    refreshHistoryMarkers(in: scene)
                    publishProjectedHistoryMarkers()
                }
            }
        }

        // MARK: Gestures

        @objc func handleRotation(_ g: UIPanGestureRecognizer) {
            guard let root = sceneRoot else { return }
            if g.state == .began {
                baseRotation = root.transform.rotation
                return
            }
            let t = g.translation(in: g.view)
            let rotY = simd_quatf(angle:  Float(t.x) * 0.005, axis: [0, 1, 0])
            let rotX = simd_quatf(angle:  Float(t.y) * 0.005, axis: [1, 0, 0])
            root.transform.rotation = rotY * rotX * baseRotation
            publishProjectedHistoryMarkers()
            if g.state == .ended { baseRotation = root.transform.rotation }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard let root = sceneRoot else { return }
            switch g.state {
            case .began:
                baseScale = root.scale.x
            case .changed:
                let s = min(max(baseScale * Float(g.scale), 3.5), 12.0)
                root.scale = [s, s, s]
                publishProjectedHistoryMarkers()
            case .ended:
                let s = min(max(baseScale * Float(g.scale), 3.5), 12.0)
                root.scale = [s, s, s]
                baseScale = s
                publishProjectedHistoryMarkers()
            default:
                break   // .cancelled / .failed — don't touch scale
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard isPickerMode, let arView, let root = sceneRoot else { return }
            let pt = g.location(in: arView)

            // Pass 1: physics hit test — walk up entity hierarchy in case hit lands on a child
            var site: InjectionSite? = nil
            var localPos: SIMD3<Float>? = nil

            for hit in arView.hitTest(pt, query: .nearest, mask: .all) {
                var candidate: Entity? = hit.entity
                while let e = candidate {
                    if let s = InjectionSite(rawValue: e.name) {
                        site = s
                        localPos = root.convert(position: hit.position, from: nil)
                        break
                    }
                    candidate = e.parent
                }
                if site != nil { break }
            }

            // Pass 2: screen-space proximity fallback — project zone entity positions to 2D
            if site == nil {
                site = nearestVisibleZone(to: pt, in: arView, root: root, hitLocalPos: &localPos)
            }

            guard let site else { return }
            selectedSite?.wrappedValue = site

            // Place selection dot
            root.findEntity(named: "__selDot")?.removeFromParent()
            let dotPos = localPos ?? SIMD3<Float>.zero
            let dot = ModelEntity(
                mesh: .generateSphere(radius: 0.018),
                materials: [UnlitMaterial(color: .systemBlue)]
            )
            dot.name     = "__selDot"
            dot.position = dotPos
            root.addChild(dot)

            onSiteTapped?(site, dotPos)
        }

        /// Projects every zone entity's world position to screen space and returns the
        /// nearest site whose projection falls within `threshold` points of `screenPt`.
        private func nearestVisibleZone(
            to screenPt: CGPoint,
            in arView: ARView,
            root: Entity,
            hitLocalPos: inout SIMD3<Float>?,
            threshold: Float = 80
        ) -> InjectionSite? {
            var bestSite: InjectionSite? = nil
            var bestDist: Float = threshold

            for site in InjectionSite.allStandard {
                guard let zoneEntity = root.findEntity(named: site.rawValue) else { continue }
                let worldPos = zoneEntity.position(relativeTo: nil)
                guard let projected = arView.project(worldPos) else { continue }
                let dx = Float(projected.x - screenPt.x)
                let dy = Float(projected.y - screenPt.y)
                let dist = (dx * dx + dy * dy).squareRoot()
                if dist < bestDist {
                    bestDist = dist
                    bestSite = site
                    hitLocalPos = zoneEntity.position(relativeTo: root)
                }
            }
            return bestSite
        }

        // MARK: History markers

        func refreshHistoryMarkers(in scene: Entity) {
            scene.findEntity(named: "__historyMarkers")?.removeFromParent()
            let container = Entity()
            container.name = "__historyMarkers"
            placeHistoryMarkers(in: container, sceneRef: scene)
            scene.addChild(container)
        }

        private func placeHistoryMarkers(in container: Entity, sceneRef: Entity) {
            for marker in historyMarkerInfos() {
                container.addChild(makeHistoryMarkerEntity(marker))
            }
        }

        private func timeAgoLabel(seconds: TimeInterval) -> String {
            let s = Int(seconds)
            if s < 60 { return "less than 1 minute ago..." }
            let minutes = s / 60
            if minutes < 60 { return "\(minutes) minute\(minutes == 1 ? "" : "s") ago" }
            let hours = minutes / 60
            if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }

        private func makeHistoryMarkerEntity(_ marker: HistoryMarkerInfo) -> Entity {
            let root = Entity()
            root.position = marker.position

            let dot = ModelEntity(
                mesh: .generateSphere(radius: 0.018),
                materials: [UnlitMaterial(color: marker.color)]
            )
            root.addChild(dot)
            return root
        }

        private func historyMarkerInfos() -> [HistoryMarkerInfo] {
            let now = Date()
            guard let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now) else { return [] }

            return historyEvents.compactMap { event in
                guard event.status == .taken,
                      let takenAt = event.takenAt,
                      takenAt >= tenDaysAgo,
                      let markerPos = event.injectionPosition else { return nil }

                let seconds = now.timeIntervalSince(takenAt)
                let days = seconds / 86400

                let color: UIColor
                switch days {
                case ..<2:  color = .systemRed
                case 2..<3: color = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.9)
                case 3..<4: color = UIColor(red: 1.0, green: 0.6,  blue: 0.0, alpha: 0.9)
                default:    color = .systemYellow.withAlphaComponent(0.9)
                }

                return HistoryMarkerInfo(
                    id: event.id,
                    position: markerPos,
                    color: color,
                    title: event.drug?.name ?? "Unknown",
                    subtitle: timeAgoLabel(seconds: seconds)
                )
            }
        }

        fileprivate func publishProjectedHistoryMarkers() {
            guard showsHistory,
                  showsHistoryCallouts,
                  let arView,
                  let root = sceneRoot else {
                projectedHistoryMarkers?.wrappedValue = []
                return
            }

            let markers = historyMarkerInfos().compactMap { marker -> BodyHistoryOverlayMarker? in
                let worldPosition = root.convert(position: marker.position, to: nil)
                guard let projectedPoint = arView.project(worldPosition) else { return nil }
                return BodyHistoryOverlayMarker(
                    id: marker.id,
                    screenPoint: CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y)),
                    title: marker.title,
                    subtitle: marker.subtitle,
                    prefersLeadingSide: CGFloat(projectedPoint.x) < arView.bounds.midX
                )
            }

            projectedHistoryMarkers?.wrappedValue = markers
        }

        // MARK: Materials

        private func applyCyanGlow(to scene: Entity) {
            scene.findEntity(named: "male")?.forEachDescendant { entity in
                guard var model = entity.components[ModelComponent.self] else { return }
                var mat = PhysicallyBasedMaterial()
                mat.baseColor       = .init(tint: UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0))
                mat.emissiveColor   = PhysicallyBasedMaterial.EmissiveColor(color: .cyan)
                mat.emissiveIntensity = 0.7
                mat.roughness       = .init(floatLiteral: 0.5)
                mat.metallic        = .init(floatLiteral: 0.0)
                model.materials     = Array(repeating: mat, count: max(1, model.materials.count))
                entity.components[ModelComponent.self] = model
            }
        }

        // Makes zone capsules invisible while keeping collision shapes for raycasting
        private func makeZonesInvisible(in scene: Entity) {
            scene.forEachDescendant { entity in
                // Hide the InjectionZones container itself and any named zone entity
                let isZoneContainer = entity.name == "InjectionZones"
                let isZone = InjectionSite(rawValue: entity.name) != nil
                guard isZoneContainer || isZone else { return }

                // Strip ModelComponent from this entity and every descendant
                entity.forEachDescendant { e in
                    e.components.remove(ModelComponent.self)
                }
            }
        }
    }
}

// MARK: - Entity traversal

private extension Entity {
    func forEachDescendant(_ block: (Entity) -> Void) {
        block(self)
        children.forEach { $0.forEachDescendant(block) }
    }
}
