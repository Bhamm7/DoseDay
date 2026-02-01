# DoseDay — Development Checklist

> Quick checklist for tracking progress. See `IMPLEMENTATION_PLAN.md` for detailed phases.

## Phase 1: Foundation
- [ ] Create Xcode project with folder structure
- [ ] Implement enums (DrugRoute, DoseStatus, InjectionSite, GlucoseUnit)
- [ ] Implement codable structs (ScheduleDefinition, ReminderSettings, LocalTime)
- [ ] Implement SwiftData models (MedicationProtocol, Drug, DoseEvent, DailyVitals, DailyNote)
- [ ] Implement DateHelpers (normalizeDay, dateFrom)
- [ ] Implement SchedulingService (generateDoseEvents, syncDoseEvents)

## Phase 2: Core Views
- [ ] App shell with TabView (Calendar, Graphs, Protocols, Settings)
- [ ] MonthView with day cell grid
- [ ] DayCellView with drug color indicators
- [ ] DayView with timeline, vitals, and notes sections
- [ ] DoseRowView with status and mark taken
- [ ] DoseEventDetailSheet
- [ ] VitalsEditorView
- [ ] NotesEditorView

## Phase 3: Protocol Management
- [ ] ProtocolListView
- [ ] ProtocolDetailView
- [ ] AddProtocolFlow (3-step wizard)
- [ ] DrugEditorView with schedule configuration

## Phase 4: Notifications
- [ ] NotificationService (schedule, cancel, reconcile)
- [ ] Permission request flow
- [ ] Test notification button in Settings

## Phase 5: Graphs
- [ ] GraphHubView with segmented picker
- [ ] SerumCalculator (exponential decay)
- [ ] SerumEstimateView with Swift Charts
- [ ] VitalsGraphView with protocol markers

## Phase 6: Settings + Polish
- [ ] SettingsView (permissions, units, export)
- [ ] Dark mode verification
- [ ] Dynamic Type / accessibility
- [ ] Empty states
- [ ] Safety disclaimer

## Phase 7: Testing
- [ ] SchedulingServiceTests
- [ ] SerumCalculatorTests
- [ ] UI smoke tests
- [ ] Manual QA checklist
