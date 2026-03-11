import Foundation
import SwiftData

@Model
final class MedicationProtocol {
    var id: UUID
    var name: String
    var notes: String
    var startDate: Date
    var endDate: Date?
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Drug.protocol)
    var drugs: [Drug] = []

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        colorHex: String = "#007AFF",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
