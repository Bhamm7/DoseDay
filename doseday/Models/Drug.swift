import Foundation
import SwiftData

private let drugColorPalette = [
    // Primary iOS system colors
    "#007AFF", "#34C759", "#FF9500", "#FF3B30",
    "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00",
    // Secondary / less common system colors
    "#FF6B35", "#30D158", "#64D2FF", "#BF5AF2",
    "#FF375F", "#FFD60A", "#00C7BE", "#32ADE6",
    // Deeper / darker shades
    "#0040DD", "#1A7F37", "#C93400", "#A2002E",
    "#6E2FBF", "#B84F00", "#007C7C", "#8E4EC6",
    // Muted / pastel-adjacent tones
    "#5E9AFF", "#7BC67E", "#FFB347", "#FF8070",
    "#C589E8", "#FFA3B5",
]

@Model
final class Drug {
    var id: UUID
    var name: String
    var routeRawValue: String
    var colorHex: String
    var doseUnit: String
    var halfLifeHours: Double
    var scheduleData: Data
    var reminderData: Data
    var createdAt: Date
    var updatedAt: Date

    var `protocol`: MedicationProtocol?

    @Relationship(deleteRule: .cascade, inverse: \DoseEvent.drug)
    var doseEvents: [DoseEvent] = []

    var route: DrugRoute {
        get { DrugRoute(rawValue: routeRawValue) ?? .oral }
        set { routeRawValue = newValue.rawValue }
    }

    var schedule: ScheduleDefinition? {
        try? ScheduleDefinition.decoded(from: scheduleData)
    }

    var reminder: ReminderSettings {
        (try? ReminderSettings.decoded(from: reminderData)) ?? .default
    }

    init(
        id: UUID = UUID(),
        name: String,
        route: DrugRoute = .oral,
        colorHex: String = drugColorPalette.randomElement()!,
        doseUnit: String = "mg",
        halfLifeHours: Double = 24,
        scheduleData: Data = Data(),
        reminderData: Data = (try? ReminderSettings.default.encoded()) ?? Data(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.routeRawValue = route.rawValue
        self.colorHex = colorHex
        self.doseUnit = doseUnit
        self.halfLifeHours = halfLifeHours
        self.scheduleData = scheduleData
        self.reminderData = reminderData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
