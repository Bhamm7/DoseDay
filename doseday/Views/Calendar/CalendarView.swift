import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProtocols: [MedicationProtocol]
    @Query private var allEvents: [DoseEvent]

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDrugIds: Set<UUID> = []

    private var monthStart: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: monthStart)!.count
    }

    private var firstWeekdayOffset: Int {
        Calendar.current.component(.weekday, from: monthStart) - 1
    }

    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var allDrugs: [Drug] { allProtocols.flatMap { $0.drugs } }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                MonthHeaderView(month: monthStart, onPrev: prevMonth, onNext: nextMonth)

                // Compound filter row
                if !allDrugs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allDrugs) { drug in
                                let active = selectedDrugIds.contains(drug.id)
                                Button {
                                    if active { selectedDrugIds.remove(drug.id) }
                                    else { selectedDrugIds.insert(drug.id) }
                                } label: {
                                    Text(drug.name)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(active ? Color(hex: drug.colorHex).opacity(0.18)
                                                           : Color.secondary.opacity(0.1))
                                        .overlay {
                                            Capsule().strokeBorder(active ? Color(hex: drug.colorHex) : .clear,
                                                                   lineWidth: 1.5)
                                        }
                                        .clipShape(Capsule())
                                        .foregroundStyle(active ? Color(hex: drug.colorHex) : .secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(drug.name)
                                .accessibilityValue(active ? "Selected" : "Not selected")
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                }

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(0 ..< firstWeekdayOffset, id: \.self) { _ in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                    ForEach(1 ... daysInMonth, id: \.self) { day in
                        let date = Calendar.current.date(byAdding: .day, value: day - 1, to: monthStart)!
                        Button {
                            selectedDate = date
                        } label: {
                            DayCellView(
                                date: date,
                                events: eventsForDay(date),
                                isToday: Calendar.current.isDateInToday(date),
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)

                // Inline day summary
                Divider().padding(.top, 4)
                HStack {
                    Text(Calendar.current.isDateInToday(selectedDate) ? "Today"
                         : selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.headline)
                    Spacer()
                    NavigationLink("See all") { DayView(date: selectedDate) }
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                let dayEvts = eventsForDay(selectedDate).sorted { $0.scheduledAt < $1.scheduledAt }
                if dayEvts.isEmpty {
                    Text("No doses scheduled")
                        .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                        .padding(.bottom, 8)
                } else {
                    ForEach(dayEvts) { event in
                        CalendarDayRow(event: event)
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .navigationTitle("Calendar")
        .toolbar {
            if !selectedDrugIds.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Select all") { selectedDrugIds = [] }
                }
            }
        }
        .onAppear { syncMonth(for: monthStart) }
    }

    private func eventsForDay(_ date: Date) -> [DoseEvent] {
        allEvents.filter {
            Calendar.current.isDate($0.scheduledAt, inSameDayAs: date)
            && (selectedDrugIds.isEmpty || selectedDrugIds.contains($0.drug?.id ?? UUID()))
        }
    }

    private func prevMonth() {
        let newStart = Calendar.current.date(byAdding: .month, value: -1, to: monthStart)!
        displayedMonth = newStart
        syncMonth(for: newStart)
    }

    private func nextMonth() {
        let newStart = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
        displayedMonth = newStart
        syncMonth(for: newStart)
    }

    private func syncMonth(for start: Date) {
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start)!
        let interval = DateInterval(start: start, end: end)
        SchedulingService().reconcileDoseEvents(
            for: allProtocols.flatMap(\.drugs),
            in: interval,
            allEvents: allEvents,
            modelContext: modelContext
        )
    }
}

private struct CalendarDayRow: View {
    @Bindable var event: DoseEvent
    @State private var showBodyPicker = false
    @State private var selectedSite: InjectionSite? = nil

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: event.drug?.colorHex ?? "#999999"))
                .frame(width: 10, height: 10)
                .padding(.leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.drug?.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                Text(event.scheduledAt, format: .dateTime.hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if event.drug?.route == .injection {
                Button {
                    selectedSite = event.resolvedInjectionSite
                    showBodyPicker = true
                } label: {
                    Image(systemName: "syringe")
                        .font(.title3)
                        .foregroundStyle(event.injectionSite != nil
                            ? Color(hex: event.drug?.colorHex ?? "#007AFF")
                            : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log injection site for \(event.drug?.name ?? "dose")")
            }
            if event.status == .scheduled {
                Button {
                    event.status = .taken
                    event.takenAt = Date()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(event.drug?.name ?? "dose") as taken")
            } else {
                StatusPillView(status: event.status)
                    .padding(.trailing)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showBodyPicker) {
            NavigationStack {
                BodyMapView(selectedSite: $selectedSite, isPickerMode: true)
                    .navigationTitle("Injection Site")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if let site = selectedSite {
                                    event.injectionSite = site.rawValue
                                }
                                showBodyPicker = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showBodyPicker = false }
                        }
                    }
            }
        }
    }
}
