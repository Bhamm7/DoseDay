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

### ScheduleDefinition (storage approach)
Prefer a codable struct persisted as Data blob or JSON string:
- frequencyType: daily | weekly | customInterval | specificWeekdays
- timesOfDay: [LocalTime] (e.g. 08:00, 20:00)
- intervalDays: Int? (for custom interval)
- weekdays: [Int]? (1=Sun ... 7=Sat)
- doseAmount: Double
- startDate: Date
- endDate: Date?

## Notes
- DoseEvents can be generated on-demand for a date range (e.g., 90 days window), or pre-generated forward.
- For v1: generate forward for N days and regenerate when schedule edits happen.
