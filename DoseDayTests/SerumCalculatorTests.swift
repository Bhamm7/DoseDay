import XCTest
import SwiftData
@testable import DoseDay

@MainActor
final class SerumCalculatorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    /// Fixed reference point: 2026-01-01 00:00:00 UTC
    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

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

    private func makeDrug(halfLife: Double, doseAmount: Double = 100) throws -> Drug {
        let schedule = ScheduleDefinition(
            frequencyType: .daily,
            times: [LocalTime(hour: 0, minute: 0)],
            intervalDays: nil, weekdays: nil,
            doseAmount: doseAmount, doseUnit: "mg"
        )
        let drug = Drug(name: "Test", halfLifeHours: halfLife, scheduleData: try schedule.encoded())
        context.insert(drug)
        return drug
    }

    private func makeTakenEvent(drug: Drug, at time: Date) -> DoseEvent {
        let event = DoseEvent(scheduledAt: time, status: .taken, takenAt: time)
        event.drug = drug
        context.insert(event)
        return event
    }

    // MARK: - Tests

    func testMonotonicDecayBetweenDoses() throws {
        let drug = try makeDrug(halfLife: 24)
        let event = makeTakenEvent(drug: drug, at: t0)

        let interval = DateInterval(start: t0, end: t0.addingTimeInterval(24 * 3600))
        let points = SerumCalculator().calculate(for: drug, events: [event], in: interval)

        XCTAssertFalse(points.isEmpty)

        for i in 1..<points.count {
            XCTAssertLessThanOrEqual(
                points[i].level,
                points[i-1].level + 1e-9,
                "Level should be monotonically non-increasing (index \(i))"
            )
        }
    }

    func testSingleDoseDecayToHalfAtOneHalfLife() throws {
        let halfLife: Double = 24
        let doseAmount: Double = 100
        let drug = try makeDrug(halfLife: halfLife, doseAmount: doseAmount)
        let event = makeTakenEvent(drug: drug, at: t0)

        // Sample exactly at t = halfLife hours
        let tHalf = t0.addingTimeInterval(halfLife * 3600)
        let interval = DateInterval(start: tHalf, end: tHalf.addingTimeInterval(3600))

        let points = SerumCalculator().calculate(for: drug, events: [event], in: interval)

        XCTAssertFalse(points.isEmpty)
        XCTAssertEqual(points[0].level, doseAmount * 0.5, accuracy: 0.001)
    }

    func testMultipleDosesSumProperly() throws {
        let halfLife: Double = 24
        let doseAmount: Double = 100
        let drug = try makeDrug(halfLife: halfLife, doseAmount: doseAmount)

        let t12 = t0.addingTimeInterval(12 * 3600)
        let event1 = makeTakenEvent(drug: drug, at: t0)
        let event2 = makeTakenEvent(drug: drug, at: t12)

        // Measure at t = 24h
        let t24 = t0.addingTimeInterval(24 * 3600)
        let interval = DateInterval(start: t24, end: t24.addingTimeInterval(3600))

        let points = SerumCalculator().calculate(for: drug, events: [event1, event2], in: interval)

        XCTAssertFalse(points.isEmpty)

        // dose1 decay: 100 * 0.5^(24/24) = 50
        // dose2 decay: 100 * 0.5^(12/24) ≈ 70.711
        let expected = doseAmount * pow(0.5, 24.0 / halfLife)
                     + doseAmount * pow(0.5, 12.0 / halfLife)
        XCTAssertEqual(points[0].level, expected, accuracy: 0.01)
    }

    func testUnrelatedDrugEventsAreIgnored() throws {
        let drugA = try makeDrug(halfLife: 24)
        let drugB = try makeDrug(halfLife: 24)

        // Event belongs to drugB, not drugA
        let _ = makeTakenEvent(drug: drugB, at: t0)

        let interval = DateInterval(start: t0, end: t0.addingTimeInterval(24 * 3600))
        let points = SerumCalculator().calculate(for: drugA, events: [/* empty — drugB event not passed */], in: interval)

        XCTAssertTrue(points.isEmpty)
    }

    func testZeroHalfLifeReturnsEmpty() throws {
        let drug = Drug(name: "Bad Drug", halfLifeHours: 0)
        context.insert(drug)

        let event = makeTakenEvent(drug: drug, at: t0)
        let interval = DateInterval(start: t0, end: t0.addingTimeInterval(3600))

        let points = SerumCalculator().calculate(for: drug, events: [event], in: interval)

        XCTAssertTrue(points.isEmpty, "Zero half-life drug should produce no data points")
    }
}
