# Information Architecture & Navigation

## Tab bar (v1.5 direction)
- Calendar
- Stats
- Protocols
- Settings

### Calendar
- MonthView (default)
  - Tap a day -> DayView(date)
  - Long-press a day -> Quick actions (optional): Add vitals, Add note

### DayView(date)
Sections (top to bottom):
1) Header: date + summary chips for drugs due
2) Timeline (expandable by hour blocks)
3) Vitals (edit/add)
4) Notes (side effects/observations)
5) Dose details sheet (when tapping a dose item)
   - scheduled time
   - mark taken (time)
   - injection site (if injected)
   - edit or delete instance (v1: allow delete instance, not schedule)

### Stats
- GraphHubView
  - Segmented sub-navigation:
    - Overview
    - Compare
    - Labs
  - Shared toolbar actions:
    - Add vitals
    - Add lab manually
    - Import bloodwork
    - Saved views (future)

#### Overview
- Purpose:
  - quick situational summary, not deep analysis
- Blocks:
  - adherence snapshot
  - serum trend snapshot for selected compound(s)
  - latest vitals summary
  - recent abnormal labs
  - recent symptom flare-ups

#### Compare
- Purpose:
  - primary analysis workspace for correlating serum, vitals, symptoms, and labs
- Top controls:
  - date range picker
  - protocol / compound multi-select
  - metric toggles
  - symptom tag filters
  - lab marker filters
  - "Out of range only" toggle for labs
  - "Show reference bands" toggle
- Chart stack (shared time axis, independent y-axes):
  1. Serum chart
  2. Vitals panel(s)
  3. Lab panel(s)
  4. Symptoms event lane
- Interaction:
  - linked crosshair / scrubber across all panels
  - tap a lab point -> open result detail
  - tap a symptom point -> open day view filtered to that date

#### Labs
- Purpose:
  - manage bloodwork reports and their individual markers
- Primary actions:
  - Add Lab Manually
  - Import PDF / photo / CSV
- Main list:
  - grouped by collection date / report
  - each report shows source, abnormal marker count, and test count
- Report detail:
  - summary header
  - all markers in the report
  - edit mappings / units / reference ranges
  - "Compare selected markers" action

#### Bloodwork entry points
- DayView:
  - quick manual entry for a known collection date
- Stats > Labs:
  - report import, review, edit, and comparison launch point
- Do not create a dedicated top-level bloodwork tab in v1.5

### Protocols
- ProtocolListView
  - ProtocolDetailView
    - Drug list with colors + schedules
    - Edit protocol / end date
    - Add drug
- AddCompoundSheet (sheet, two tabs)
  - Tab: Single Compound (default)
    - Drug fields inline (name, route, schedule, reminder, color)
    - Save → auto-creates a named protocol from drug name
  - Tab: Protocol
    - Protocol name + color + dates + notes
    - Inline drug list with Add Drug button
    - Save persists immediately; add more drugs later via ProtocolDetailView
    - No review step

### Settings
- Notification permissions + default reminder settings
- Units preferences (kg/lb, mmol/L vs mg/dL for glucose)
- Data export (optional)
