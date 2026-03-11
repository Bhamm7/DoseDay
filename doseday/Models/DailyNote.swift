import Foundation
import SwiftData

@Model
final class DailyNote {
    var id: UUID
    var date: Date
    var sideEffects: String
    var observations: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sideEffects: String = "",
        observations: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.sideEffects = sideEffects
        self.observations = observations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
