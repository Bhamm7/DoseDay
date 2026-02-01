# TODO — DoseDay Implementation Plan

## Tech decisions (lock these early)
- [ ] iOS target: iOS 17+
- [ ] UI: SwiftUI
- [ ] Storage: SwiftData
- [ ] Charts: Swift Charts
- [ ] Notifications: UserNotifications

## Project scaffolding
- [ ] Create /docs/doseday/ folder and commit specs
- [ ] Create app modules/folders:
  - Models/
  - Scheduling/
  - Notifications/
  - Views/Calendar/
  - Views/Day/
  - Views/Protocols/
  - Views/Graphs/
  - Settings/

## Models (SwiftData)
- [ ] Implement Protocol model
- [ ] Implement Drug model with ScheduleDefinition + ReminderSettings codable blobs
- [ ] Implement DoseEvent model
- [ ] Implement DailyVitals model
- [ ] Implement DailyNote model
- [ ] Add enums: DrugRoute, DoseStatus, InjectionSite, units

## Scheduling engine
- [ ] Implement LocalTime
- [ ] Implement generateDoseEvents(drug, from, to)
- [ ] Implement syncDoseEvents (non-destructive for past taken/skipped)
- [ ] Add helpers: normalizeDay, dateFrom(day,time)

## Protocol creation flow
- [ ] ProtocolListView
- [ ] AddProtocolWizard:
  - [ ] Step 1: protocol name, start/end
  - [ ] Step 2: add drug (repeatable)
  - [ ] Step 3: review
- [ ] Drug editor:
  - [ ] name, route, unit, color picker
  - [ ] schedule type + times
  - [ ] half-life hours
  - [ ] reminders settings

## Calendar
- [ ] Month grid UI
- [ ] Data source: dose events within displayed grid range
- [ ] Day cell indicators: up to 3 drug colors + overflow count
- [ ] Tap -> DayView(date)

## Day view
- [ ] Timeline list grouped by time
- [ ] Dose row: time, drug label, status, mark taken
- [ ] Dose detail sheet:
  - [ ] mark taken now or at time
  - [ ] skip + reason (optional)
  - [ ] injection site picker if injection
- [ ] Vitals editor section:
  - [ ] weight, BP, RHR, glucose
- [ ] Notes editor section:
  - [ ] side effects, observations

## Notifications
- [ ] Settings: request permission + global defaults
- [ ] Schedule notifications for future DoseEvents where reminder enabled
- [ ] Reschedule on:
  - [ ] schedule edit
  - [ ] app launch reconciliation
- [ ] Add "test notification" button

## Graphs
- [ ] Graph hub view with two segments
- [ ] Serum estimate graph:
  - [ ] select drugs
  - [ ] date range
  - [ ] placeholder exponential decay sampling
  - [ ] label as estimate
- [ ] Vitals graph:
  - [ ] metric toggles
  - [ ] date range
  - [ ] protocol start/end markers

## Polish
- [ ] Dark mode
- [ ] Accessibility: dynamic type, VoiceOver labels
- [ ] Empty states (no protocols, no events, no vitals)
- [ ] Basic in-app safety copy

## Testing
- [ ] Unit tests for scheduling + sampler
- [ ] UI smoke tests
- [ ] Manual QA checklist run before release
