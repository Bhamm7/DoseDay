import Foundation
import SwiftData

@Model
final class DailySymptom {
    var id: UUID
    var date: Date
    var tag: SymptomTag?
    var severity: Int   // 1 = mild, 2 = moderate, 3 = severe
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        tag: SymptomTag? = nil,
        severity: Int = 1,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.tag = tag
        self.severity = severity
        self.notes = notes
        self.createdAt = createdAt
    }
}
