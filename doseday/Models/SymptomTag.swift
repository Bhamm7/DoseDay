import Foundation
import SwiftData

@Model
final class SymptomTag {
    var id: UUID
    var name: String
    var colorHex: String
    var isSystem: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DailySymptom.tag)
    var symptoms: [DailySymptom] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        isSystem: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

extension SymptomTag {
    static let systemTags: [(name: String, colorHex: String)] = [
        ("Headache",         "#FF3B30"),
        ("Nausea",           "#FF9500"),
        ("Fatigue",          "#FFCC00"),
        ("Mood Changes",     "#AF52DE"),
        ("Acne",             "#FF2D55"),
        ("Libido Changes",   "#FF6B6B"),
        ("Sleep Issues",     "#5856D6"),
        ("Hot Flashes",      "#FF6A00"),
        ("Brain Fog",        "#8E8E93"),
        ("Bloating",         "#34C759"),
        ("Water Retention",  "#5AC8FA"),
        ("Joint Pain",       "#007AFF"),
    ]
}
