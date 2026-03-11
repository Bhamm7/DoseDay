import XCTest
import SwiftData
@testable import DoseDay

@MainActor
final class SchedulingServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: MedicationProtocol.self, Drug.self, DoseEvent.self, DailyVitals.self, DailyNote.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    // MARK: - Helpers

    private func makeDrug(schedule: ScheduleDefinition) throws -> Drug {
        let drug = Drug(name: "Test", scheduleData: try schedule.encoded())
        context.insert(drug)
        return drug
    }

    /// Jan 1 2026 is a Thursday.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour; c.minute = minute
        return Calendar.current.date(from: c)!
    }

    // MARK: - Tests

    func testDailyScheduleGeneratesCorrectTimes() throws {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 8, minute: 0), LocalTime(hour: 20, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        let drug = try makeDrug(schedule: schedule)

        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 4)) // 3 days

        let events = SchedulingService().generateDoseEvents(for: drug, in: interval, existingEvents: [])

        XCTAssertEqual(events.count, 6) // 3 days × 2 times

        for event in events {
            let hour = Calendar.current.component(.hour, from: event.scheduledAt)
            XCTAssertTrue(hour == 8 || hour == 20, "Unexpected hour: \(hour)")
        }
    }

    func testSpecificDaysScheduleFiltersCorrectly() throws {
        // Monday only (weekday index 2 in Calendar)
        let schedule = ScheduleDefinition(
            frequencyType: .specificDays,
            times: [LocalTime(hour: 9, minute: 0)],
            intervalDays: nil, weekdays: [2],
            doseAmount: 10, doseUnit: "mg"
        )
        let drug = try makeDrug(schedule: schedule)

        // Jan 5 2026 is Monday; range Mon–Sun (7 days, only 1 Monday)
        let interval = DateInterval(start: date(2026, 1, 5), end: date(2026, 1, 12))

        let events = SchedulingService().generateDoseEvents(for: drug, in: interval, existingEvents: [])

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(Calendar.current.component(.weekday, from: events[0].scheduledAt), 2)
    }

    func testEveryNDaysAlignsWithStartDate() throws {
        // intervalDays = 3, protocol start = Jan 1
        // Expected fires: Jan 1, 4, 7 (days 0, 3, 6) within a 9-day range [Jan1, Jan10)
        let schedule = ScheduleDefinition(
            frequencyType: .everyNDays,
            times: [LocalTime(hour: 8, minute: 0)],
            intervalDays: 3, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        let proto = MedicationProtocol(name: "Protocol", startDate: date(2026, 1, 1))
        context.insert(proto)

        let drug = Drug(name: "Test", scheduleData: try schedule.encoded())
        context.insert(drug)
        drug.protocol = proto

        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 10))

        let events = SchedulingService()
            .generateDoseEvents(for: drug, in: interval, existingEvents: [])
            .sorted { $0.scheduledAt < $1.scheduledAt }

        XCTAssertEqual(events.count, 3)

        // Verify each gap is exactly 3 days
        for i in 1..<events.count {
            let gap = Calendar.current.dateComponents(
                [.day], from: events[i-1].scheduledAt, to: events[i].scheduledAt
            ).day!
            XCTAssertEqual(gap, 3)
        }
    }

    func testSyncPreservesPastTakenEvents() throws {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 8, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        let drug = try makeDrug(schedule: schedule)

        // Past taken event at 08:00 on Jan 1
        let pastDose = date(2026, 1, 1, hour: 8)
        let takenEvent = DoseEvent(scheduledAt: pastDose, status: .taken, takenAt: pastDose)
        takenEvent.drug = drug
        context.insert(takenEvent)

        // Change schedule to 20:00 — the old 08:00 slot is no longer expected
        let newSchedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 20, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        drug.scheduleData = try newSchedule.encoded()

        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 3))

        let (_, toDelete) = SchedulingService().syncDoseEvents(
            for: drug, in: interval, existingEvents: [takenEvent]
        )

        XCTAssertFalse(
            toDelete.contains { $0.scheduledAt == pastDose },
            "Past taken event must never be deleted"
        )
    }

    func testProtocolEndDateStopsScheduling() throws {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 8, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        // Protocol ends Jan 5 — events should only be generated Jan 1–4
        let proto = MedicationProtocol(
            name: "Short Protocol",
            startDate: date(2026, 1, 1),
            endDate: date(2026, 1, 5)
        )
        context.insert(proto)

        let drug = Drug(name: "Test", scheduleData: try schedule.encoded())
        context.insert(drug)
        drug.protocol = proto

        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 10))
        let events = SchedulingService().generateDoseEvents(for: drug, in: interval, existingEvents: [])

        XCTAssertEqual(events.count, 4) // Jan 1, 2, 3, 4 (Jan 5 is excluded by endDate)
        XCTAssertTrue(events.allSatisfy { $0.scheduledAt < date(2026, 1, 5) })
    }

    func testProtocolStartDateDelaysScheduling() throws {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 8, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        // Protocol starts Jan 5 — no events before that
        let proto = MedicationProtocol(name: "Late Start", startDate: date(2026, 1, 5))
        context.insert(proto)

        let drug = Drug(name: "Test", scheduleData: try schedule.encoded())
        context.insert(drug)
        drug.protocol = proto

        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 10))
        let events = SchedulingService().generateDoseEvents(for: drug, in: interval, existingEvents: [])

        XCTAssertEqual(events.count, 5) // Jan 5, 6, 7, 8, 9
        XCTAssertTrue(events.allSatisfy { $0.scheduledAt >= date(2026, 1, 5) })
    }

    func testSyncSkipsAlreadyExistingDates() throws {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 8, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: 10, doseUnit: "mg"
        )
        let drug = try makeDrug(schedule: schedule)

        let existingDate = date(2026, 2, 1, hour: 8)
        let existing = DoseEvent(scheduledAt: existingDate, status: .scheduled)
        existing.drug = drug
        context.insert(existing)

        let interval = DateInterval(start: date(2026, 2, 1), end: date(2026, 2, 4))

        let (toInsert, toDelete) = SchedulingService().syncDoseEvents(
            for: drug, in: interval, existingEvents: [existing]
        )

        // Feb 2 and 3 should be new; Feb 1 already exists so must not be re-inserted
        XCTAssertFalse(toInsert.contains { $0.scheduledAt == existingDate })
        XCTAssertEqual(toInsert.count, 2)
        XCTAssertTrue(toDelete.isEmpty)
    }
}
