import Foundation
import SwiftData

@Model
final class LabResult {
    var id: UUID
    var date: Date
    var testName: String
    var value: Double
    var unit: String
    var referenceRangeLow: Double?
    var referenceRangeHigh: Double?
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var report: LabReport?

    var isOutOfRange: Bool {
        if let low = referenceRangeLow, value < low { return true }
        if let high = referenceRangeHigh, value > high { return true }
        return false
    }

    init(
        id: UUID = UUID(),
        date: Date,
        testName: String,
        value: Double,
        unit: String,
        referenceRangeLow: Double? = nil,
        referenceRangeHigh: Double? = nil,
        notes: String = "",
        report: LabReport? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.testName = testName
        self.value = value
        self.unit = unit
        self.referenceRangeLow = referenceRangeLow
        self.referenceRangeHigh = referenceRangeHigh
        self.notes = notes
        self.report = report
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
