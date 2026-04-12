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
│   ├── Schedule/
│   ├── Reports/
│   ├── Protocols/
│   └── Tools/
└── Resources/
```

### 1.2 Implement Models (SwiftData)
See `docs/doseday/03_DATA_MODEL.md`

1. **Enums** (create first - no dependencies):
   - `DrugRoute` (oral, injection, other)
   - `DoseStatus` (scheduled, taken, skipped)
   - `InjectionSite` (leftGlute, rightGlute, etc.)
   - `GlucoseUnit` (mmolL, mgdL)

2. **Codable Structs**:
   - `ScheduleDefinition` (frequencyType, timesOfDay, intervalDays, weekdays, doseAmount, startDate, endDate)
   - `ReminderSettings` (enabled, minutesBefore, soundEnabled)
   - `LocalTime` (hour, minute)

3. **SwiftData Models** (in order):
   - `MedicationProtocol` (avoid naming conflict with Swift Protocol)
   - `Drug` (references MedicationProtocol)
   - `DoseEvent` (references Drug)
   - `DailyVitals`
   - `DailySymptoms` (was DailyNote)
   - `LabEntry` (new - bloodwork results)

### 1.3 Implement Scheduling Engine
See `docs/doseday/04_SCHEDULING_ENGINE.md`

1. `DateHelpers.swift`:
   - `normalizeDay(date:)` → midnight Date
   - `dateFrom(day:time:)` → combines day + LocalTime

2. `SchedulingService.swift`:
   - `generateDoseEvents(drug:from:to:)` → [DoseEvent]
   - `syncDoseEvents(drug:range:existingEvents:)` → reconcile without deleting past taken/skipped

---

## Phase 2: Core Views (Schedule Tab)

### 2.1 App Shell + Navigation
See `docs/doseday/02_INFORMATION_ARCHITECTURE.md`

- TabView with 4 tabs: Schedule, Reports, Protocols, Tools
- Tab icons: 📅, 📊, 💊, 🔧

### 2.2 Schedule Tab
See `docs/doseday/06_UI_SPECS.md`

1. `ScheduleView.swift` (main container):
   - Date state management
   - Header with navigation arrows + calendar toggle

2. `ScheduleHeaderView.swift`:
   - ◀ ▶ day navigation buttons
   - Date display (tappable for picker)
   - ▼ chevron for calendar expand/collapse
   - 📌 pin toggle

3. `InlineCalendarView.swift`:
   - Month grid with day cells
   - Drug color indicators
   - Adherence shading
   - Day tap → updates parent date state

4. `DoseTimelineView.swift`:
   - List of doses sorted by scheduledAt
   - Query DoseEvents for selected date

5. `DoseRowView.swift`:
   - Time, drug name (with color dot), status pill
   - "Mark taken" button for scheduled doses
   - Injection site subtitle if applicable

6. `DoseEventDetailSheet.swift`:
   - Mark taken (now or custom time)
   - Skip with optional reason
   - Injection site picker (if route == injection)

7. `VitalsEditorView.swift`:
   - Weight, BP (sys/dia), HR, glucose fields
   - Save button

8. `SymptomsEditorView.swift`:
   - Side effects + observations text fields
   - Save button

---

## Phase 3: Protocol Management

### 3.1 Protocol List
1. `ProtocolListView.swift`:
   - List of protocols with name + date range + drug dots
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
   - Dose amount with built-in calculator
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
   - Add "Test Notification" button in Tools > Settings

---

## Phase 5: Reports Tab

See `docs/doseday/07_GRAPHS_SPECS.md`

### 5.1 Reports Hub
`ReportsView.swift` with segmented picker:
- Compounds | Vitals | Labs

### 5.2 Compounds Segment
1. `CompoundsReportView.swift`:
   - Drug multi-select
   - Date range picker (7D, 30D, 90D, Custom)

2. `SerumCalculator.swift`:
   - Exponential decay: `contribution(t) = dose * 0.5^((t - doseTime) / halfLife)`
   - Sum contributions at sampled intervals
   - Sample at 1h (≤30 days) or 3h (>30 days)

3. Display with Swift Charts:
   - LineMark per drug (colored by drug.colorHex)
   - Label as "Visual Estimate Only"

### 5.3 Vitals Segment
1. `VitalsReportView.swift`:
   - Toggle buttons for: Weight, BP, HR, Glucose
   - Date range picker

2. Display with Swift Charts:
   - PointMark + LineMark per metric
   - RuleMark for protocol start/end markers

### 5.4 Labs Segment
1. `LabsReportView.swift`:
   - Metric selector
   - Date range picker
   - Reference range bands
   - "Add Labs" button → Tools > Labs Entry

---

## Phase 6: Tools Tab

### 6.1 Tools List View
`ToolsView.swift`:
- List with navigation links to each tool
- Settings section at bottom

### 6.2 Labs Entry
`LabsEntryView.swift`:
- Date picker
- Dynamic form for common lab markers
- Custom marker support
- Save to LabEntry model

### 6.3 Reconstitution Calculator
`ReconstitutionCalculatorView.swift`:
- Powder amount input
- BAC water volume input
- Concentration output table
- Dose → volume calculator

### 6.4 Insights
`InsightsView.swift`:
- AI-generated observations (placeholder for v1)
- Adherence summary
- Vitals trends summary
- Refresh button

### 6.5 Export
`ExportView.swift`:
- Format picker (CSV/JSON)
- Data type selection
- Share sheet integration

### 6.6 Settings
`SettingsView.swift`:
- Notification permission status + toggle
- Default reminder settings
- Unit preferences (kg/lb, glucose units)
- Test notification button
- About section with disclaimer

---

## Phase 7: Polish

- Dark mode support (automatic via SwiftUI)
- Dynamic Type support
- VoiceOver labels on interactive elements
- Empty states for: no protocols, no events, no vitals, no labs
- Safety disclaimer in About section
- Loading states and error handling

---

## Phase 8: Testing

See `docs/doseday/10_TESTING_QA.md`

### 8.1 Unit Tests
- `SchedulingServiceTests.swift`:
  - Daily schedule generates correct times
  - Weekday schedule filters correctly
  - Every-N-days aligns with startDate
  - Sync preserves past taken/skipped events

- `SerumCalculatorTests.swift`:
  - Monotonic decay between doses
  - Multiple doses sum correctly

- `ReconstitutionCalculatorTests.swift`:
  - Concentration calculations accurate
  - Dose to volume conversions correct

### 8.2 UI Tests
- Create protocol with 2 drugs
- Verify schedule shows doses
- Mark dose taken → verify status updates
- Add vitals → verify on Reports
- Add labs → verify on Reports

---

## Build Order Summary

| Phase | Components | Dependencies |
|-------|-----------|--------------|
| 1 | Models + Scheduling | None |
| 2 | Schedule Tab | Phase 1 |
| 3 | Protocol Management | Phase 1 |
| 4 | Notifications | Phase 1, 3 |
| 5 | Reports Tab | Phase 1, 2 |
| 6 | Tools Tab | Phase 1 |
| 7 | Polish | All phases |
| 8 | Testing | All phases |

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
