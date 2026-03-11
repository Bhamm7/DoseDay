import Foundation

struct SchedulingService {
    private let calendar = Calendar.current

    func generateDoseEvents(
        for drug: Drug,
        in dateInterval: DateInterval,
        existingEvents: [DoseEvent]
    ) -> [DoseEvent] {
        guard let schedule = drug.schedule, !schedule.times.isEmpty else { return [] }

        let existingScheduledDates = Set(existingEvents.map { $0.scheduledAt })
        var events: [DoseEvent] = []

        var currentDate = calendar.startOfDay(for: dateInterval.start)
        let endDate = dateInterval.end

        while currentDate < endDate {
            if shouldFire(schedule: schedule, drug: drug, on: currentDate) {
                for time in schedule.times {
                    var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    components.hour = time.hour
                    components.minute = time.minute
                    components.second = 0

                    guard let scheduledAt = calendar.date(from: components),
                          scheduledAt >= dateInterval.start,
                          scheduledAt < dateInterval.end else { continue }

                    if !existingScheduledDates.contains(scheduledAt) {
                        events.append(DoseEvent(scheduledAt: scheduledAt, status: .scheduled))
                    }
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return events
    }

    func syncDoseEvents(
        for drug: Drug,
        in dateInterval: DateInterval,
        existingEvents: [DoseEvent]
    ) -> (toInsert: [DoseEvent], toDelete: [DoseEvent]) {
        guard drug.schedule != nil else { return ([], []) }

        let now = Date()

        // Never touch past taken/skipped events
        let settledDates = Set(
            existingEvents
                .filter { $0.scheduledAt < now && ($0.status == .taken || $0.status == .skipped) }
                .map { $0.scheduledAt }
        )

        // Generate the expected full set (pass empty existing so we get all dates)
        let expected = generateDoseEvents(for: drug, in: dateInterval, existingEvents: [])
        let expectedDates = Set(expected.map { $0.scheduledAt })

        // Modifiable existing events: scheduled ones not yet settled
        let modifiableExisting = existingEvents.filter { !settledDates.contains($0.scheduledAt) }
        let existingDates = Set(modifiableExisting.map { $0.scheduledAt })

        let toInsert = expected.filter { !existingDates.contains($0.scheduledAt) && !settledDates.contains($0.scheduledAt) }
        let toDelete = modifiableExisting.filter { !expectedDates.contains($0.scheduledAt) }

        return (toInsert, toDelete)
    }

    // MARK: - Private

    private func shouldFire(schedule: ScheduleDefinition, drug: Drug, on date: Date) -> Bool {
        // Clamp to protocol active window
        let dayStart = calendar.startOfDay(for: date)
        if let proto = drug.protocol {
            let protoStart = calendar.startOfDay(for: proto.startDate)
            guard dayStart >= protoStart else { return false }
            if let protoEnd = proto.endDate {
                guard dayStart < calendar.startOfDay(for: protoEnd) else { return false }
            }
        }

        switch schedule.frequencyType {
        case .daily:
            return true
        case .specificDays:
            let weekday = calendar.component(.weekday, from: date)
            return schedule.weekdays?.contains(weekday) ?? false
        case .everyNDays:
            guard let intervalDays = schedule.intervalDays, intervalDays > 0 else { return false }
            let anchor = calendar.startOfDay(for: drug.protocol?.startDate ?? date)
            let target = calendar.startOfDay(for: date)
            let daysSince = calendar.dateComponents([.day], from: anchor, to: target).day ?? 0
            return daysSince >= 0 && daysSince % intervalDays == 0
        }
    }
}
