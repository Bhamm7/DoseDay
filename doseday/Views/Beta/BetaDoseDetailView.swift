import SwiftUI
import Charts
import SwiftData
import simd

struct BetaDoseDetailView: View {
    @Query private var allEvents: [DoseEvent]
    @Bindable var event: DoseEvent

    @State private var selectedSite: InjectionSite?
    @State private var selectedPosition: SIMD3<Float>?

    private let calendar = Calendar.current

    private var schedule: ScheduleDefinition? {
        event.drug?.schedule
    }

    private var sameDrugEvents: [DoseEvent] {
        guard let drugId = event.drug?.id else { return [] }
        return allEvents.filter { $0.drug?.id == drugId }
    }

    private var serumInterval: DateInterval {
        let centerDay = calendar.startOfDay(for: event.scheduledAt)
        let start = calendar.date(byAdding: .day, value: -7, to: centerDay) ?? centerDay
        let endDay = calendar.date(byAdding: .day, value: 7, to: centerDay) ?? centerDay
        let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        return DateInterval(start: start, end: end)
    }

    private var serumPoints: [SerumDataPoint] {
        guard let drug = event.drug else { return [] }
        return SerumCalculator().calculate(for: drug, events: sameDrugEvents, in: serumInterval)
    }

    private var recentInjectionEvents: [DoseEvent] {
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: event.scheduledAt)) ?? event.scheduledAt
        let lowerBound = calendar.date(byAdding: .day, value: -10, to: dayEnd) ?? dayEnd

        return allEvents.filter {
            $0.drug?.route == .injection &&
            $0.status == .taken &&
            ($0.takenAt ?? .distantPast) >= lowerBound &&
            ($0.takenAt ?? .distantPast) < dayEnd
        }
    }

    private var syringeCalculation: SyringeCalculation? {
        guard event.drug?.route == .injection,
              let schedule,
              schedule.doseAmount > 0,
              let reconstitutionAmount = event.drug?.reconstitutionAmount,
              let diluentML = event.drug?.reconstitutionDiluentML,
              reconstitutionAmount > 0,
              diluentML > 0 else {
            return nil
        }

        let concentration = reconstitutionAmount / diluentML
        guard concentration > 0 else { return nil }

        let drawML = schedule.doseAmount / concentration
        let drawUnits = drawML * 100
        guard drawML > 0, drawUnits > 0 else { return nil }

        return SyringeCalculation(
            concentration: concentration,
            drawML: drawML,
            drawUnits: drawUnits
        )
    }

    private var isInjection: Bool {
        event.drug?.route == .injection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                doseSummaryCard
                serumCard

                if isInjection {
                    syringeCard
                    bodyMapCard
                } else {
                    nonInjectionCard
                }
            }
            .padding()
        }
        .navigationTitle(event.drug?.name ?? "Medication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            selectedSite = event.resolvedInjectionSite
            selectedPosition = event.injectionPosition
        }
    }

    private var doseSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.drug?.name ?? "Unknown")
                        .font(.title3.weight(.semibold))

                    Text(event.drug?.route.displayName ?? "Medication")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                BetaDetailCompactValue(
                    title: "Scheduled",
                    value: event.scheduledAt.formatted(.dateTime.hour().minute())
                )

                BetaDetailCompactValue(
                    title: "Dose",
                    value: doseDisplayText ?? "Unavailable"
                )
            }

            HStack(spacing: 8) {
                CompactActionButton(
                    title: event.status == .taken ? "Taken" : "Mark Taken",
                    isProminent: true,
                    isDisabled: event.status == .taken,
                    action: markTaken
                )

                CompactActionButton(
                    title: event.status == .skipped ? "Skipped" : "Skip",
                    isProminent: false,
                    isDisabled: event.status == .skipped,
                    action: skipDose
                )

                Spacer()
            }

            if let takenAt = event.takenAt, event.status == .taken {
                Text("Logged at \(takenAt.formatted(.dateTime.hour().minute()))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if event.status == .skipped {
                Text("Dose marked as skipped.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var serumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Serum Levels")
                .font(.headline)

            if let drug = event.drug, drug.halfLifeHours > 0 {
                if serumPoints.isEmpty {
                    Text("No taken doses yet to estimate serum levels for this compound.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    Chart {
                        ForEach(serumPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Level", point.level)
                            )
                            .foregroundStyle(Color(hex: drug.colorHex))
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(x: .value("Dose", event.scheduledAt))
                            .foregroundStyle(Color.secondary.opacity(0.45))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartYAxisLabel("Relative")
                    .frame(height: 170)
                }

                Text("Visual estimate only, based on logged taken doses and the configured half-life.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add a half-life to this compound to see its serum estimate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            Text(isInjection
                 ? "The chart gives context before using the syringe helper and injection map below."
                 : "This view shows the current estimate around the selected dose date.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var syringeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("U100 Syringe")
                .font(.headline)

            if let syringeCalculation {
                U100SyringeView(
                    drawUnits: syringeCalculation.drawUnits,
                    accentColor: Color(hex: event.drug?.colorHex ?? "#007AFF"),
                    isOverflow: syringeCalculation.isOverflow
                )
                .frame(height: 120)

                HStack(spacing: 12) {
                    BetaDetailValueCard(
                        title: "Draw",
                        value: "\(syringeCalculation.drawML.formatted(.number.precision(.fractionLength(2)))) mL"
                    )
                    BetaDetailValueCard(
                        title: "U100",
                        value: "\(syringeCalculation.drawUnits.formatted(.number.precision(.fractionLength(0...1)))) units"
                    )
                }

                Text("Concentration: \(syringeCalculation.concentration.formatted(.number.precision(.fractionLength(0...2)))) \(event.drug?.doseUnit ?? "")/mL")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if syringeCalculation.isOverflow {
                    Text("This dose exceeds a single 1.0 mL / 100 unit U100 syringe draw.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("Add a compound amount and diluent volume in the drug editor to calculate the syringe draw.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var bodyMapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Injection Location")
                .font(.headline)

            BodyMapView(
                selectedSite: $selectedSite,
                historyEvents: recentInjectionEvents,
                showsHistory: true,
                isPickerMode: true,
                onSiteTapped: { _, position in
                    selectedPosition = position
                }
            )
            .frame(height: 380)

            if let selectedSite {
                Text("Selected: \(selectedSite.displayName)")
                    .font(.subheadline.weight(.medium))
            } else if let resolvedSite = event.resolvedInjectionSite {
                Text("Current site: \(resolvedSite.displayName)")
                    .font(.subheadline.weight(.medium))
            }

            Button(event.resolvedInjectionSite == nil ? "Save Injection Site" : "Update Injection Site") {
                saveInjectionSite()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedSite == nil)

            Text("Tap a location on the body model to log the site while keeping recent heat markers visible.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var nonInjectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No Injection Guidance")
                .font(.headline)

            Text("This route does not use the syringe or body-map logger. Status changes still update the shared dose history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var doseDisplayText: String? {
        guard let schedule else { return nil }
        let amount = schedule.doseAmount.formatted(.number.precision(.fractionLength(0...2)))
        return "\(amount) \(schedule.doseUnit)"
    }

    private func markTaken() {
        event.status = .taken
        event.takenAt = Date()
        event.updatedAt = Date()
        NotificationService().cancel(for: event)
    }

    private func skipDose() {
        event.status = .skipped
        event.takenAt = nil
        event.updatedAt = Date()
        NotificationService().cancel(for: event)
    }

    private func saveInjectionSite() {
        guard let selectedSite else { return }

        event.injectionSite = selectedSite.rawValue
        if let selectedPosition {
            event.injectionPositionX = selectedPosition.x
            event.injectionPositionY = selectedPosition.y
            event.injectionPositionZ = selectedPosition.z
        }
        if event.status != .taken || event.takenAt == nil {
            event.status = .taken
            event.takenAt = Date()
        }
        event.updatedAt = Date()
        NotificationService().cancel(for: event)
    }
}

private struct CompactActionButton: View {
    let title: String
    let isProminent: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 78)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
    }

    private var foregroundColor: Color {
        if isProminent {
            return .white
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isProminent {
            return isDisabled ? Color.green.opacity(0.45) : .green
        }
        return Color.secondary.opacity(0.08)
    }

    private var borderColor: Color {
        if isProminent {
            return .green.opacity(0.2)
        }
        return Color.secondary.opacity(0.12)
    }
}

private struct BetaDetailCompactValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct BetaDetailValueCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SyringeCalculation {
    let concentration: Double
    let drawML: Double
    let drawUnits: Double

    var isOverflow: Bool {
        drawUnits > 100
    }
}
