import SwiftUI
import SwiftData

struct DayView: View {
    let date: Date

    @Query private var allEvents: [DoseEvent]
    @Query private var allVitals: [DailyVitals]
    @Query private var allNotes: [DailyNote]

    @State private var selectedEvent: DoseEvent? = nil

    private var dayEvents: [DoseEvent] {
        allEvents
            .filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: date) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var dayVitals: DailyVitals? {
        allVitals.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private var dayNote: DailyNote? {
        allNotes.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private var drugSummaries: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        var order: [String] = []
        for event in dayEvents {
            guard let name = event.drug?.name else { continue }
            if counts[name] == nil { order.append(name) }
            counts[name, default: 0] += 1
        }
        return order.map { (name: $0, count: counts[$0]!) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.title2.weight(.bold))

                    if !drugSummaries.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(drugSummaries, id: \.name) { summary in
                                    Text("\(summary.name) • \(summary.count)")
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Timeline
                VStack(alignment: .leading, spacing: 0) {
                    Text("Doses")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    if dayEvents.isEmpty {
                        Text("No doses scheduled")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(dayEvents) { event in
                            DoseRowView(
                                event: event,
                                onMarkTaken: {
                                    event.status = .taken
                                    event.takenAt = Date()
                                },
                                onTap: { selectedEvent = event }
                            )
                            Divider().padding(.leading, 56)
                        }
                    }
                }

                // Injection map (read-only heat map, shown when any injection event exists)
                if dayEvents.contains(where: { $0.drug?.route == .injection }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Injection Map")
                            .font(.headline)
                            .padding(.horizontal)
                        BodyMapView(historyEvents: dayEvents, isPickerMode: false)
                    }
                }

                // Vitals
                VitalsEditorView(date: date, vitals: dayVitals)

                // Lab Results
                LabResultsEditorView(date: date)

                // Symptoms
                SymptomsEditorView(date: date)

                // Notes
                NotesEditorView(date: date, note: dayNote)
            }
            .padding(.vertical)
        }
        .navigationTitle(date.formatted(.dateTime.month(.abbreviated).day()))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            DoseEventDetailSheet(event: event)
        }
    }
}
