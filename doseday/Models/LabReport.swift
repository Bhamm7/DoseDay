import Foundation
import SwiftData

@Model
final class LabReport {
    var id: UUID
    var collectedAt: Date
    var sourceName: String?
    var sourceTypeRawValue: String
    var reportTitle: String?
    var notes: String
    var attachmentLocalPath: String?
    var originalFilename: String?
    var importedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LabResult.report)
    var results: [LabResult] = []

    var sourceType: LabSourceType {
        get { LabSourceType(rawValue: sourceTypeRawValue) ?? .manual }
        set { sourceTypeRawValue = newValue.rawValue }
    }

    var displayTitle: String {
        if let title = reportTitle, !title.isEmpty { return title }
        if let sourceName, !sourceName.isEmpty { return sourceName }
        return collectedAt.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var abnormalResultsCount: Int {
        results.filter(\.isOutOfRange).count
    }

    init(
        id: UUID = UUID(),
        collectedAt: Date,
        sourceName: String? = nil,
        sourceType: LabSourceType = .manual,
        reportTitle: String? = nil,
        notes: String = "",
        attachmentLocalPath: String? = nil,
        originalFilename: String? = nil,
        importedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.collectedAt = collectedAt
        self.sourceName = sourceName
        self.sourceTypeRawValue = sourceType.rawValue
        self.reportTitle = reportTitle
        self.notes = notes
        self.attachmentLocalPath = attachmentLocalPath
        self.originalFilename = originalFilename
        self.importedAt = importedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
