# Scheduling Engine

## Goal
Given (Protocol + Drug.schedule), produce DoseEvents across a date range:
- Used by Calendar (monthly) + Day view + Notifications
- Must support editing drug schedule and updating future events

## Supported schedule types (v1)
1) Daily at specific times
2) Specific weekdays at specific times (e.g., Mon/Wed/Fri at 9:00)
3) Every N days at specific time(s) (e.g., every 3 days at 10:00)

## Core functions (Swift)
- normalizeDay(date) -> Date (midnight in current calendar)
- generateDoseEvents(drug, from: Date, to: Date) -> [DoseEventDraft]
  - drafts include scheduledAt + amount + unit + references
- syncDoseEvents(drug, range, existingEvents) -> apply create/update/delete
  - Do not delete past taken events; only modify future scheduled ones

## Editing rules
- When schedule changes:
  - Leave past events untouched (especially taken/skipped)
  - For future events:
    - delete scheduled events not matching new schedule (status == scheduled)
    - create missing events
    - update scheduledAt time shifts if needed

## Date/time representation
- Use Calendar + DateComponents
- Define LocalTime struct:
  - hour: Int
  - minute: Int
- Combine day + local time using Calendar.date(from:)

## Performance
- Generate only necessary window:
  - Calendar month view: generate for month +/- padding (e.g., 42-day grid)
  - Day view: generate for that day
  - Graphs: generate for selected range
- Cache per drug/day if needed.

## Edge cases
- Timezone changes: store scheduledAt in absolute Date but re-render in local TZ.
- DST transitions: handle missing or repeated local times gracefully.
