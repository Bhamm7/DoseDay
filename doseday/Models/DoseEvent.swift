import Foundation
import SwiftData

@Model
final class DoseEvent {
    var id: UUID
    var scheduledAt: Date
    var statusRawValue: String
    var takenAt: Date?
    var injectionSite: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var drug: Drug?

    var status: DoseStatus {
        get { DoseStatus(rawValue: statusRawValue) ?? .scheduled }
        set { statusRawValue = newValue.rawValue }
    }

    var resolvedInjectionSite: InjectionSite? {
        guard let raw = injectionSite else { return nil }
        return InjectionSite(rawValue: raw)
    }

    init(
        id: UUID = UUID(),
        scheduledAt: Date,
        status: DoseStatus = .scheduled,
        takenAt: Date? = nil,
        injectionSite: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.scheduledAt = scheduledAt
        self.statusRawValue = status.rawValue
        self.takenAt = takenAt
        self.injectionSite = injectionSite
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
