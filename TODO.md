# DoseDay — Development Checklist

> Quick checklist for tracking progress. See `IMPLEMENTATION_PLAN.md` for detailed phases.

## Phase 1: Foundation
- [ ] Create Xcode project with folder structure
- [ ] Implement enums (DrugRoute, DoseStatus, InjectionSite, GlucoseUnit)
- [ ] Implement codable structs (ScheduleDefinition, ReminderSettings, LocalTime)
- [ ] Implement SwiftData models (MedicationProtocol, Drug, DoseEvent, DailyVitals, DailySymptoms, LabEntry)
- [ ] Implement DateHelpers (normalizeDay, dateFrom)
- [ ] Implement SchedulingService (generateDoseEvents, syncDoseEvents)

## Phase 2: Schedule Tab
- [ ] App shell with TabView (Schedule, Reports, Protocols, Tools)
- [ ] ScheduleView with date state management
- [ ] ScheduleHeaderView (date nav, calendar toggle, pin button)
- [ ] InlineCalendarView (month grid, day indicators, adherence shading)
- [ ] DoseTimelineView
- [ ] DoseRowView with status and mark taken
- [ ] DoseEventDetailSheet
- [ ] VitalsEditorView
- [ ] SymptomsEditorView

## Phase 3: Protocol Management
- [ ] ProtocolListView
- [ ] ProtocolDetailView
- [ ] AddProtocolFlow (3-step wizard)
- [ ] DrugEditorView with dose calculator

## Phase 4: Notifications
- [ ] NotificationService (schedule, cancel, reconcile)
- [ ] Permission request flow
- [ ] Test notification button in Settings

## Phase 5: Reports Tab
- [ ] ReportsView with segmented picker
- [ ] CompoundsReportView (serum estimates)
- [ ] SerumCalculator (exponential decay)
- [ ] VitalsReportView with protocol markers
- [ ] LabsReportView with reference ranges

## Phase 6: Tools Tab
- [ ] ToolsView (list container)
- [ ] LabsEntryView
- [ ] ReconstitutionCalculatorView
- [ ] InsightsView (AI observations placeholder)
- [ ] ExportView (CSV/JSON)
- [ ] SettingsView (permissions, units, about)

## Phase 7: Polish
- [ ] Dark mode verification
- [ ] Dynamic Type / accessibility
- [ ] VoiceOver labels
- [ ] Empty states
- [ ] Loading states and error handling
- [ ] Safety disclaimer

## Phase 8: Testing
- [ ] SchedulingServiceTests
- [ ] SerumCalculatorTests
- [ ] ReconstitutionCalculatorTests
- [ ] UI smoke tests
- [ ] Manual QA checklist
