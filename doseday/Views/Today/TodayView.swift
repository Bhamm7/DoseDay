import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProtocols: [MedicationProtocol]
    @Query private var allEvents: [DoseEvent]
    @Query private var allVitals: [DailyVitals]

    @State private var dateSelection: TodayDateSelection = .today
    @State private var selectedEvent: DoseEvent?
    @State private var injectionEvent: DoseEvent?

    private let calendar = Calendar.current

    private var allDrugs: [Drug] {
        allProtocols.flatMap(\.drugs)
    }

    private var protocolSyncToken: String {
        allDrugs
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSinceReferenceDate)" }
            .joined(separator: "|")
    }

    private var activeDate: Date {
        let baseDate = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: dateSelection.dayOffset, to: baseDate) ?? baseDate
    }

    private var dayInterval: DateInterval {
        let end = calendar.date(byAdding: .day, value: 1, to: activeDate) ?? activeDate
        return DateInterval(start: activeDate, end: end)
    }

    private var dayEvents: [DoseEvent] {
        let now = Date()
        return allEvents
            .filter { dayInterval.contains($0.scheduledAt) }
            .sorted { lhs, rhs in
                let lhsRank = eventSortRank(lhs, now: now)
                let rhsRank = eventSortRank(rhs, now: now)
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs.scheduledAt < rhs.scheduledAt
            }
    }

    private var dayVitals: DailyVitals? {
        allVitals.first { calendar.isDate($0.date, inSameDayAs: activeDate) }
    }

    private var overdueCount: Int {
        let now = Date()
        return dayEvents.filter { $0.status == .scheduled && $0.scheduledAt < now }.count
    }

    private var remainingCount: Int {
        let now = Date()
        return dayEvents.filter { $0.status == .scheduled && $0.scheduledAt >= now }.count
    }

    private var takenCount: Int {
        dayEvents.filter { $0.status == .taken }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(activeDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.title2.weight(.bold))

                    Picker("Day", selection: $dateSelection) {
                        ForEach(TodayDateSelection.allCases) { selection in
                            Text(selection.rawValue).tag(selection)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                TodaySummaryRow(
                    overdueCount: overdueCount,
                    remainingCount: remainingCount,
                    takenCount: takenCount
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scheduled Meds")
                            .font(.headline)
                        Spacer()
                        Text("\(dayEvents.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if dayEvents.isEmpty {
                        Text(emptyStateCopy)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 10) {
                            ForEach(dayEvents) { event in
                                TodayDoseRow(
                                    event: event,
                                    onMarkTaken: { markTaken(event) },
                                    onOpenSitePicker: { injectionEvent = event },
                                    onOpenDetails: { selectedEvent = event }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                VitalsEditorView(date: activeDate, vitals: dayVitals, title: "Vitals & Weight")

                NavigationLink {
                    DayView(date: activeDate)
                } label: {
                    HStack {
                        Text("Open Full Day")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: protocolSyncToken) {
            syncAgendaWindow()
        }
        .sheet(item: $selectedEvent) { event in
            DoseEventDetailSheet(event: event)
        }
        .sheet(item: $injectionEvent) { event in
            TodayInjectionSiteSheet(event: event)
        }
    }

    private var emptyStateCopy: String {
        if allDrugs.isEmpty {
            return "No compounds scheduled yet. Add a protocol to populate your daily agenda."
        }
        return "No doses scheduled for \(dateSelection.rawValue.lowercased())."
    }

    private func syncAgendaWindow() {
        guard !allDrugs.isEmpty else { return }

        let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) ?? Date()
        let end = calendar.date(byAdding: .day, value: 31, to: start) ?? start
        SchedulingService().reconcileDoseEvents(
            for: allDrugs,
            in: DateInterval(start: start, end: end),
            allEvents: allEvents,
            modelContext: modelContext
        )
    }

    private func eventSortRank(_ event: DoseEvent, now: Date) -> Int {
        switch event.status {
        case .scheduled:
            return event.scheduledAt < now ? 0 : 1
        case .taken:
            return 2
        case .skipped:
            return 3
        }
    }

    private func markTaken(_ event: DoseEvent) {
        event.status = .taken
        event.takenAt = Date()
        event.updatedAt = Date()
        NotificationService().cancel(for: event)
    }
}

private enum TodayDateSelection: String, CaseIterable, Identifiable {
    case yesterday = "Yesterday"
    case today = "Today"
    case tomorrow = "Tomorrow"

    var id: String { rawValue }

    var dayOffset: Int {
        switch self {
        case .yesterday:
            return -1
        case .today:
            return 0
        case .tomorrow:
            return 1
        }
    }
}

private struct TodaySummaryRow: View {
    let overdueCount: Int
    let remainingCount: Int
    let takenCount: Int

    var body: some View {
        HStack(spacing: 12) {
            SummaryStatCard(
                title: "Overdue",
                value: overdueCount,
                tint: overdueCount > 0 ? .red : .secondary
            )
            SummaryStatCard(
                title: "Remaining",
                value: remainingCount,
                tint: .orange
            )
            SummaryStatCard(
                title: "Taken",
                value: takenCount,
                tint: .green
            )
        }
    }
}

private struct SummaryStatCard: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct TodayDoseRow: View {
    @Bindable var event: DoseEvent

    let onMarkTaken: () -> Void
    let onOpenSitePicker: () -> Void
    let onOpenDetails: () -> Void

    private var drugColor: Color {
        Color(hex: event.drug?.colorHex ?? "#999999")
    }

    private var doseText: String? {
        guard let schedule = event.drug?.schedule else { return nil }
        let amount = schedule.doseAmount.formatted(.number.precision(.fractionLength(0...2)))
        return "\(amount) \(schedule.doseUnit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(drugColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(event.drug?.name ?? "Unknown")
                            .font(.body.weight(.semibold))
                        Spacer()
                        StatusPillView(status: event.status)
                    }

                    Text(event.scheduledAt, format: .dateTime.hour().minute())
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let doseText {
                        Text(doseText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if event.drug?.route == .injection, let site = event.resolvedInjectionSite {
                        Text("Site: \(site.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 8) {
                if event.drug?.route == .injection {
                    Button(event.resolvedInjectionSite == nil ? "Log Site" : "Edit Site", action: onOpenSitePicker)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                if event.status == .scheduled {
                    Button("Mark Taken", action: onMarkTaken)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                Button("Details", action: onOpenDetails)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct TodayInjectionSiteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: DoseEvent

    @State private var selectedSite: InjectionSite?
    @State private var selectedPosition: SIMD3<Float>?

    var body: some View {
        NavigationStack {
            BodyMapView(
                selectedSite: $selectedSite,
                isPickerMode: true,
                onSiteTapped: { _, position in
                    selectedPosition = position
                }
            )
            .padding()
            .navigationTitle("Injection Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSelection()
                    }
                    .disabled(selectedSite == nil)
                }
            }
            .onAppear {
                selectedSite = event.resolvedInjectionSite
                selectedPosition = event.injectionPosition
            }
        }
    }

    private func saveSelection() {
        guard let selectedSite else { return }

        event.injectionSite = selectedSite.rawValue
        if let selectedPosition {
            event.injectionPositionX = selectedPosition.x
            event.injectionPositionY = selectedPosition.y
            event.injectionPositionZ = selectedPosition.z
        }
        if event.status != .taken {
            event.status = .taken
            event.takenAt = Date()
        }
        event.updatedAt = Date()
        NotificationService().cancel(for: event)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
}
