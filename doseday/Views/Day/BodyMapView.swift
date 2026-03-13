import SwiftUI
import RealityKit
import BodyModel

// MARK: - BodyMapView (SwiftUI shell)

struct BodyMapView: View {
    var selectedSite: Binding<InjectionSite?>?
    var historyEvents: [DoseEvent] = []
    var isPickerMode: Bool

    var body: some View {
        VStack(spacing: 12) {
            BodyARViewRepresentable(
                selectedSite: selectedSite,
                historyEvents: historyEvents,
                isPickerMode: isPickerMode
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .layoutPriority(1)

            if isPickerMode, let site = selectedSite?.wrappedValue {
                Text(site.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            if !isPickerMode {
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
                ("0–3d",   Color.red),
                ("4–14d",  Color.orange),
                ("15–30d", Color.yellow),
                ("31–90d", Color.green),
                ("90d+",   Color.secondary),
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

// MARK: - UIViewRepresentable

struct BodyARViewRepresentable: UIViewRepresentable {
    var selectedSite: Binding<InjectionSite?>?
    var historyEvents: [DoseEvent]
    var isPickerMode: Bool

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

        context.coordinator.arView       = arView
        context.coordinator.selectedSite = selectedSite
        context.coordinator.isPickerMode = isPickerMode
        context.coordinator.historyEvents = historyEvents

        Task { await context.coordinator.loadScene() }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selectedSite  = selectedSite
        context.coordinator.isPickerMode  = isPickerMode
        context.coordinator.historyEvents = historyEvents
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var sceneRoot: Entity?
        var selectedSite: Binding<InjectionSite?>?
        var isPickerMode  = false
        var historyEvents: [DoseEvent] = []
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

            if !isPickerMode {
                placeHistoryDots(in: scene)
            }

            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(scene)
            await MainActor.run {
                arView.scene.addAnchor(anchor)
                sceneRoot = scene
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
            if g.state == .ended { baseRotation = root.transform.rotation }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard let root = sceneRoot else { return }
            if g.state == .began { baseScale = root.scale.x; return }
            let s = min(max(baseScale * Float(g.scale), 0.3), 3.0)
            root.scale = [s, s, s]
            if g.state == .ended { baseScale = s }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard isPickerMode, let arView, let root = sceneRoot else { return }
            let pt = g.location(in: arView)

            // Raycast from screen point against collision shapes
            let hits = arView.hitTest(pt, query: .nearest, mask: .all)
            guard let hit = hits.first,
                  let site = InjectionSite(rawValue: hit.entity.name) else { return }

            selectedSite?.wrappedValue = site

            // Place dot at exact raycasted surface point
            root.findEntity(named: "__selDot")?.removeFromParent()
            let localPos = root.convert(position: hit.position, from: nil)
            let dot = ModelEntity(
                mesh: .generateSphere(radius: 0.018),
                materials: [UnlitMaterial(color: .systemBlue)]
            )
            dot.name   = "__selDot"
            dot.position = localPos
            root.addChild(dot)
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

                if isZone {
                    // Generate collision from the capsule mesh before stripping visuals
                    entity.generateCollisionShapes(recursive: true)
                }
                // Strip ModelComponent from this entity and every descendant
                entity.forEachDescendant { e in
                    e.components.remove(ModelComponent.self)
                }
            }
        }

        // MARK: History dots

        private func placeHistoryDots(in scene: Entity) {
            for site in InjectionSite.allStandard {
                guard let zone = scene.findEntity(named: site.rawValue),
                      let color = heatUIColor(for: site) else { continue }
                let dot = ModelEntity(
                    mesh: .generateSphere(radius: 0.022),
                    materials: [UnlitMaterial(color: color)]
                )
                dot.position = zone.position(relativeTo: scene)
                scene.addChild(dot)
            }
        }

        private func heatUIColor(for site: InjectionSite) -> UIColor? {
            let now = Date()
            let dates = historyEvents.compactMap { event -> Date? in
                guard event.resolvedInjectionSite == site,
                      event.status == .taken,
                      let takenAt = event.takenAt else { return nil }
                return takenAt
            }
            guard let latest = dates.max() else { return nil }
            let days = Calendar.current.dateComponents([.day], from: latest, to: now).day ?? 999
            switch days {
            case 0...3:   return .systemRed.withAlphaComponent(0.9)
            case 4...14:  return .systemOrange.withAlphaComponent(0.9)
            case 15...30: return .systemYellow.withAlphaComponent(0.9)
            case 31...90: return .systemGreen.withAlphaComponent(0.9)
            default:      return .systemGray.withAlphaComponent(0.6)
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
