# UI Specs (SwiftUI)

## Design language
- Clean, readable, calendar-first
- Colors are per-drug; use them as small accents (dots/chips), not full backgrounds.
- Accessibility:
  - support Dynamic Type
  - color not the only signal: include labels in Day/Dose details

## Calendar (MonthView)
- Header: month name + prev/next
- 7-column grid
- Each cell:
  - day number
  - up to 3 drug indicators:
    - small colored dots OR mini chips with first letter
  - if more than 3: "+N"
- Tap opens DayView(date)

## DayView
### Header
- Date
- Summary row: chips like "DrugA • 2", "DrugB • 1"

### Timeline (Expandable)
- Group by hour blocks or show a simple list sorted by time
- Each Dose item row:
  - time
  - drug name (with color dot)
  - status pill: Scheduled / Taken / Skipped
  - CTA: "Mark taken" (if scheduled)
- Tapping row opens DoseEventDetailSheet

### Vitals section
- Fields:
  - weight
  - blood pressure (two fields)
  - resting HR
  - blood glucose
- Save per day; show last saved time.
- Provide units toggles in Settings (display preference only)

### Notes section
- Side effects: multiline text
- Observations: multiline text
- Autosave or explicit Save button (pick one and be consistent; v1 prefer explicit Save)

## Protocols
- List protocols
- Detail page shows drugs with:
  - name
  - route
  - half-life
  - schedule summary string (human readable)
  - color swatch
- Add/edit flows are sheet-based wizard

## Injection site UX
- In DoseEventDetailSheet, if route == injection:
  - injection site picker (simple list)
  - optional free text if "Other"
- Display injection site:
  - DayView dose row: show as small subtitle if space
  - Calendar day cell: do NOT show per-dose site (too dense); instead show in DayView
