import Foundation
import SwiftData

@Model
final class DailyVitals {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var systolicBP: Int?
    var diastolicBP: Int?
    var restingHR: Int?
    var glucoseValue: Double?
    var glucoseUnitRawValue: String

    var glucoseUnit: GlucoseUnit {
        get { GlucoseUnit(rawValue: glucoseUnitRawValue) ?? .mmolL }
        set { glucoseUnitRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double? = nil,
        systolicBP: Int? = nil,
        diastolicBP: Int? = nil,
        restingHR: Int? = nil,
        glucoseValue: Double? = nil,
        glucoseUnit: GlucoseUnit = .mmolL
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.weightKg = weightKg
        self.systolicBP = systolicBP
        self.diastolicBP = diastolicBP
        self.restingHR = restingHR
        self.glucoseValue = glucoseValue
        self.glucoseUnitRawValue = glucoseUnit.rawValue
    }
}
