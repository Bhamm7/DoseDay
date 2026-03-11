import Foundation

struct LocalTime: Codable, Comparable, Hashable {
    var hour: Int
    var minute: Int

    static func < (lhs: LocalTime, rhs: LocalTime) -> Bool {
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        return lhs.minute < rhs.minute
    }

    var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

struct ScheduleDefinition: Codable {
    var frequencyType: FrequencyType
    var times: [LocalTime]
    var intervalDays: Int?
    var weekdays: [Int]?
    var doseAmount: Double
    var doseUnit: String

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) throws -> ScheduleDefinition {
        try JSONDecoder().decode(ScheduleDefinition.self, from: data)
    }
}

struct ReminderSettings: Codable {
    var enabled: Bool
    var minutesBefore: Int
    var soundEnabled: Bool

    static let `default` = ReminderSettings(enabled: true, minutesBefore: 15, soundEnabled: true)

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) throws -> ReminderSettings {
        try JSONDecoder().decode(ReminderSettings.self, from: data)
    }
}
