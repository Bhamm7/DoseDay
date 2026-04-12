import SwiftUI
import SwiftData

// MARK: - Time-of-day grouping

enum TimeOfDay: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case beforeBed = "Before Bed"

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case ..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .beforeBed
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.rise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .beforeBed: return "moon.stars"
        }
    }
}

// MARK: - ScheduleView

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProtocols: [MedicationProtocol]
    @Query private var allEvents: [DoseEvent]
    @Query private var allVitals: [DailyVitals]
    @Query private var allNotes: [DailyNote]
    @Query private var allSymptoms: [DailySymptom]
    @Query(sort: \SymptomTag.sortOrder) private var allTags: [SymptomTag]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var isCalendarExpanded = false
    @State private var collapsedSections: Set<TimeOfDay> = []
    @State private var selectedEvent: DoseEvent? = nil
    @State private var showSymptomPicker = false

    private var dayEvents: [DoseEvent] {
        allEvents
            .filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var dayVitals: DailyVitals? {
        allVitals.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var dayNote: DailyNote? {
        allNotes.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var groupedEvents: [(TimeOfDay, [DoseEvent])] {
        var groups: [TimeOfDay: [DoseEvent]] = [:]
        for event in dayEvents {
            let hour = Calendar.current.component(.hour, from: event.scheduledAt)
            let tod = TimeOfDay.from(hour: hour)
            groups[tod, default: []].append(event)
        }
        return TimeOfDay.allCases.compactMap { tod in
            guard let events = groups[tod], !events.isEmpty else { return nil }
            return (tod, events)
        }
    }

    private var daySymptomsList: [DailySymptom] {
        allSymptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var recentInjectionEvents: [DoseEvent] {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: selectedDate) ?? selectedDate
        return allEvents.filter {
            $0.drug?.route == .injection &&
            $0.status == .taken &&
            ($0.takenAt ?? .distantPast) >= tenDaysAgo
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarDrawerView(
                selectedDate: $selectedDate,
                displayedMonth: $displayedMonth,
                isExpanded: $isCalendarExpanded,
                allEvents: allEvents
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Compact vitals
                    CompactVitalsView(date: selectedDate, vitals: dayVitals)
                        .padding(.top, 12)

                    // Time-grouped doses
                    if groupedEvents.isEmpty {
                        Text("No doses scheduled")
                            .font(.subheadline)
                            .foregroundStyle(DDTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(groupedEvents, id: \.0) { tod, events in
                            timeSection(tod, events: events)
                        }
                    }

                    // Injection map
                    if dayEvents.contains(where: { $0.drug?.route == .injection }) || !recentInjectionEvents.isEmpty {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("Injection Map", icon: "syringe")
                                BodyMapView(historyEvents: recentInjectionEvents, isPickerMode: false)
                            }
                        }
                    }

                    // Notes & Symptoms — unified
                    sectionCard {
                        NotesSymptomsSectionView(
                            date: selectedDate,
                            note: dayNote,
                            daySymptoms: daySymptomsList,
                            onAddSymptom: { showSymptomPicker = true }
                        )
                    }

                    // Lab results
                    sectionCard {
                        LabResultsEditorView(date: selectedDate)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(DDTheme.canvas)
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            DoseEventDetailSheet(event: event)
        }
        .sheet(isPresented: $showSymptomPicker) {
            SymptomPickerSheet(date: selectedDate)
        }
        .onAppear { syncMonth(for: displayedMonth) }
        .onChange(of: displayedMonth) { _, newMonth in syncMonth(for: newMonth) }
        .onChange(of: selectedDate) { _, _ in
            let cal = Calendar.current
            let selectedMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate))!
            if selectedMonth != cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))! {
                displayedMonth = selectedMonth
            }
        }
    }

    // MARK: - Time section

    private func timeSection(_ tod: TimeOfDay, events: [DoseEvent]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if collapsedSections.contains(tod) {
                        collapsedSections.remove(tod)
                    } else {
                        collapsedSections.insert(tod)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: tod.icon)
                        .font(.caption)
                        .foregroundStyle(DDTheme.accent)
                        .frame(width: 20)

                    Text(tod.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DDTheme.textPrimary)

                    Text("\(events.count)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(DDTheme.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(DDTheme.cardBorder)
                        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusSmall))

                    Spacer()

                    Image(systemName: collapsedSections.contains(tod) ? "chevron.right" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DDTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Dose rows
            if !collapsedSections.contains(tod) {
                VStack(spacing: 0) {
                    ForEach(events) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            ScheduleDoseRow(event: event)
                        }
                        .buttonStyle(.plain)

                        if event.id != events.last?.id {
                            Divider()
                                .padding(.leading, 66)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .background(DDTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DDTheme.radiusLarge)
                .strokeBorder(DDTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding()
        .background(DDTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DDTheme.radiusLarge)
                .strokeBorder(DDTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DDTheme.accent)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DDTheme.textPrimary)
        }
    }

    private func syncMonth(for month: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        let interval = DateInterval(start: start, end: end)
        SchedulingService().reconcileDoseEvents(
            for: allProtocols.flatMap(\.drugs),
            in: interval,
            allEvents: allEvents,
            modelContext: modelContext
        )
    }
}
