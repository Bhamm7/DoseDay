# DoseDay Implementation Plan

> Succinct, phased plan for building the DoseDay iOS app.
> Refer to `docs/doseday/` for detailed specs on each component.

## Tech Stack
- **Platform**: iOS 17+
- **UI**: SwiftUI
- **Storage**: SwiftData (local-first)
- **Charts**: Swift Charts
- **Notifications**: UserNotifications

---

## Phase 1: Foundation (Models + Scheduling)

### 1.1 Create Xcode Project
```
DoseDay/
├── DoseDayApp.swift
├── Models/
├── Services/
│   ├── Scheduling/
│   └── Notifications/
├── Views/
│   ├── Calendar/
│   ├── Day/
│   ├── Protocols/
│   ├── Graphs/
│   └── Settings/
└── Resources/
```

### 1.2 Implement Models (SwiftData)
See `docs/doseday/03_DATA_MODEL.md`

1. **Enums** (create first - no dependencies):
   - `DrugRoute` (oral, injection, other)
   - `DoseStatus` (scheduled, taken, skipped)
   - `InjectionSite` (leftGlute, rightGlute, etc.)
   - `GlucoseUnit` (mmolL, mgdL)

2. **ScheduleDefinition** (Codable struct):
   - frequencyType, timesOfDay, intervalDays, weekdays, doseAmount, startDate, endDate

3. **ReminderSettings** (Codable struct):
   - enabled, minutesBefore, soundEnabled

4. **LocalTime** (Codable struct):
   - hour: Int, minute: Int

5. **SwiftData Models** (in order):
   - `MedicationProtocol` (avoid naming conflict with Swift Protocol)
   - `Drug` (references MedicationProtocol)
   - `DoseEvent` (references Drug)
   - `DailyVitals`
   - `DailyNote`

### 1.3 Implement Scheduling Engine
See `docs/doseday/04_SCHEDULING_ENGINE.md`

1. `DateHelpers.swift`:
   - `normalizeDay(date:)` → midnight Date
   - `dateFrom(day:time:)` → combines day + LocalTime

2. `SchedulingService.swift`:
   - `generateDoseEvents(drug:from:to:)` → [DoseEvent]
   - `syncDoseEvents(drug:range:existingEvents:)` → reconcile without deleting past taken/skipped

---

## Phase 2: Core Views (Calendar + Day)

### 2.1 App Shell + Navigation
See `docs/doseday/02_INFORMATION_ARCHITECTURE.md`

- TabView with 4 tabs: Calendar, Graphs, Protocols, Settings
- Create placeholder views for each tab

### 2.2 Calendar View
See `docs/doseday/06_UI_SPECS.md`

1. `MonthView.swift`:
   - Month header with prev/next navigation
   - 7-column LazyVGrid
   - Query DoseEvents for visible date range

2. `DayCellView.swift`:
   - Day number
   - Up to 3 colored dots for drugs
   - "+N" overflow indicator

### 2.3 Day View
See `docs/doseday/06_UI_SPECS.md`

1. `DayView.swift`:
   - Date header with drug summary chips
   - Timeline list sorted by scheduledAt
   - Vitals section
   - Notes section

2. `DoseRowView.swift`:
   - Time, drug name (with color dot), status pill
   - "Mark taken" button for scheduled doses

3. `DoseEventDetailSheet.swift`:
   - Mark taken (now or custom time)
   - Skip with optional reason
   - Injection site picker (if route == injection)

4. `VitalsEditorView.swift`:
   - Weight, BP (sys/dia), HR, glucose fields
   - Save button

5. `NotesEditorView.swift`:
   - Side effects + observations text fields
   - Save button

---

## Phase 3: Protocol Management

### 3.1 Protocol List
1. `ProtocolListView.swift`:
   - List of protocols with name + date range
   - Add button → AddProtocolFlow

2. `ProtocolDetailView.swift`:
   - Protocol info
   - Drug list with colors, routes, schedule summaries
   - Edit/End protocol actions

### 3.2 Add Protocol Wizard
1. `AddProtocolFlow.swift` (sheet-based wizard):
   - Step 1: Name + start date + optional end date
   - Step 2: Add drugs (repeatable)
   - Step 3: Review + Save

2. `DrugEditorView.swift`:
   - Name, route, unit, color picker
   - Schedule type + times picker
   - Half-life hours
   - Reminder settings toggle

---

## Phase 4: Notifications

See `docs/doseday/05_NOTIFICATIONS.md`

1. `NotificationService.swift`:
   - Request permission
   - `scheduleNotification(for doseEvent:)` using UNUserNotificationCenter
   - `cancelNotification(for doseEvent:)`
   - `reconcileNotifications()` on app launch

2. Integration:
   - Schedule notifications when DoseEvents are created
   - Reschedule when drug schedule changes
   - Add "Test Notification" button in Settings

---

## Phase 5: Graphs

See `docs/doseday/07_GRAPHS_SPECS.md`

### 5.1 Graph Hub
`GraphHubView.swift` with segmented picker:
- Serum Estimates
- Vitals

### 5.2 Serum Estimate Graph
1. `SerumEstimateView.swift`:
   - Drug multi-select
   - Date range picker (7D, 30D, 90D, Custom)

2. `SerumCalculator.swift`:
   - Exponential decay: `contribution(t) = dose * 0.5^((t - doseTime) / halfLife)`
   - Sum contributions at sampled intervals
   - Sample at 1h (≤30 days) or 3h (>30 days)

3. Display with Swift Charts:
   - LineMark per drug (colored by drug.colorHex)
   - Label as "Visual Estimate Only"

### 5.3 Vitals Graph
1. `VitalsGraphView.swift`:
   - Toggle buttons for: Weight, BP, HR, Glucose
   - Date range picker

2. Display with Swift Charts:
   - PointMark + LineMark per metric
   - RuleMark for protocol start/end markers

---

## Phase 6: Settings + Polish

### 6.1 Settings View
1. `SettingsView.swift`:
   - Notification permission status + toggle
   - Default reminder settings
   - Units preferences (kg/lb, mmol/L vs mg/dL)
   - Test notification button
   - Export data (optional)

### 6.2 Polish
- Dark mode support (automatic via SwiftUI)
- Dynamic Type support
- VoiceOver labels on interactive elements
- Empty states for: no protocols, no events, no vitals
- Safety disclaimer in About section

---

## Phase 7: Testing

See `docs/doseday/10_TESTING_QA.md`

### 7.1 Unit Tests
- `SchedulingServiceTests.swift`:
  - Daily schedule generates correct times
  - Weekday schedule filters correctly
  - Every-N-days aligns with startDate
  - Sync preserves past taken/skipped events

- `SerumCalculatorTests.swift`:
  - Monotonic decay between doses
  - Multiple doses sum correctly

### 7.2 UI Tests
- Create protocol with 2 drugs
- Verify calendar shows colored dots
- Mark dose taken → verify status updates
- Add vitals → verify on graph

---

## Build Order Summary

| Phase | Components | Dependencies |
|-------|-----------|--------------|
| 1 | Models + Scheduling | None |
| 2 | Calendar + Day Views | Phase 1 |
| 3 | Protocol Management | Phase 1 |
| 4 | Notifications | Phase 1, 3 |
| 5 | Graphs | Phase 1, 2 |
| 6 | Settings + Polish | Phase 4 |
| 7 | Testing | All phases |

---

## Key Files Reference

| Spec | Location |
|------|----------|
| Product Overview | `docs/doseday/00_PRODUCT_OVERVIEW.md` |
| Requirements | `docs/doseday/01_REQUIREMENTS.md` |
| Information Architecture | `docs/doseday/02_INFORMATION_ARCHITECTURE.md` |
| Data Model | `docs/doseday/03_DATA_MODEL.md` |
| Scheduling Engine | `docs/doseday/04_SCHEDULING_ENGINE.md` |
| Notifications | `docs/doseday/05_NOTIFICATIONS.md` |
| UI Specs | `docs/doseday/06_UI_SPECS.md` |
| Graphs Specs | `docs/doseday/07_GRAPHS_SPECS.md` |
| Storage & Sync | `docs/doseday/08_STORAGE_SYNC.md` |
| Privacy | `docs/doseday/09_ANALYTICS_PRIVACY.md` |
| Testing | `docs/doseday/10_TESTING_QA.md` |
