# Data Model (SwiftData)

## Entities

### Protocol
- id: UUID
- name: String
- startDate: Date
- endDate: Date? (nil means ongoing)
- createdAt: Date
- updatedAt: Date
- drugs: [Drug] (relationship)

### Drug
- id: UUID
- protocolId: UUID (or relationship backref)
- name: String
- colorHex: String (store as hex; convert to Color in UI)
- route: DrugRoute (enum: oral, injection, other)
- unit: DoseUnit (enum or string)
- halfLifeHours: Double? (optional; used for serum estimate)
- schedule: ScheduleDefinition (stored model; see Scheduling doc)
- reminder: ReminderSettings
- createdAt, updatedAt

### DoseEvent (generated instances)
Represents a scheduled administration occurrence.
- id: UUID
- drugId: UUID (relationship)
- scheduledAt: Date
- status: DoseStatus (scheduled, taken, skipped)
- takenAt: Date?
- skippedReason: String?
- injectionSite: InjectionSite? (only if injection)
- notes: String? (per-dose note optional)
- createdAt, updatedAt

### DailyVitals
- id: UUID
- date: Date (normalized to day)
- weightKg: Double?
- bpSystolic: Int?
- bpDiastolic: Int?
- restingHr: Int?
- glucose: Double?
- glucoseUnit: GlucoseUnit (mmolL, mgdL) OR store normalized + display preference
- createdAt, updatedAt

### DailyNote
- id: UUID
- date: Date (normalized)
- sideEffects: String?
- observations: String?
- createdAt, updatedAt

### LabReport
- id: UUID
- collectedAt: Date (date/time of blood draw; allow day-only precision if needed)
- sourceName: String? (lab/provider/portal)
- sourceType: LabSourceType (manual, pdfImport, photoImport, csvImport, portalImport)
- reportTitle: String? (e.g. "CBC", "Hormone Panel")
- notes: String?
- attachmentLocalPath: String? (app-managed local file reference)
- originalFilename: String?
- importedAt: Date?
- createdAt, updatedAt
- results: [LabResult] (relationship)

### LabResult
- id: UUID
- reportId: UUID? (relationship; nil allowed for quick manual v1 entry)
- date: Date (normalized to day for graphing; usually mirrors report collection day)
- testName: String
- value: Double
- unit: String
- referenceRangeLow: Double?
- referenceRangeHigh: Double?
- notes: String?
- createdAt, updatedAt

## Enums

### DrugRoute
- oral
- injection
- other

### DoseStatus
- scheduled
- taken
- skipped

### InjectionSite (v1 simple list)
- leftGlute
- rightGlute
- leftQuad
- rightQuad
- leftDelt
- rightDelt
- abdomenLeft
- abdomenRight
- other(String?) (store as free text if selected)

### LabSourceType
- manual
- pdfImport
- photoImport
- csvImport
- portalImport

### ScheduleDefinition (storage approach)
Prefer a codable struct persisted as Data blob or JSON string:
- frequencyType: daily | weekly | customInterval | specificWeekdays
- timesOfDay: [LocalTime] (e.g. 08:00, 20:00)
- intervalDays: Int? (for custom interval)
- weekdays: [Int]? (1=Sun ... 7=Sat)
- doseAmount: Double
- startDate: Date
- endDate: Date?

## Lab modeling notes

### Why add LabReport?
- Upload/import needs a parent object representing a single blood draw or file-backed report.
- Multiple LabResults from the same collection date should stay grouped for editing, provenance, and compare workflows.
- Attachment metadata belongs on the report, not on each individual marker.

### Import workflow model
- Import creates one LabReport plus many LabResults.
- User reviews:
  - collection date
  - source
  - parsed marker names
  - units
  - reference ranges
- Saving the import persists both the report and its normalized marker rows.

### Stats implications
- Compare view filters LabResults by marker name and date range.
- Labs view groups results by LabReport.
- "Out of range only" uses referenceRangeLow / referenceRangeHigh on LabResult.

## Notes
- DoseEvents can be generated on-demand for a date range (e.g., 90 days window), or pre-generated forward.
- For v1: generate forward for N days and regenerate when schedule edits happen.
- Avoid storing large binary files directly inside SwiftData rows for lab attachments; prefer app-managed local files plus metadata on LabReport.
