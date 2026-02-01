# Information Architecture & Navigation

## Tab bar (v1)
- Calendar
- Graphs
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

### Graphs
- GraphHubView
  - SerumEstimateGraph (select drug(s), date range)
  - VitalsGraph (toggle metrics)
  - Protocol markers appear as vertical dots/lines

### Protocols
- ProtocolListView
  - ProtocolDetailView
    - Drug list with colors + schedules
    - Edit protocol / end date
    - Add drug
- AddProtocolFlow (wizard style)
  1) Name + start/end
  2) Add drugs (repeating)
  3) Review + Save

### Settings
- Notification permissions + default reminder settings
- Units preferences (kg/lb, mmol/L vs mg/dL for glucose)
- Data export (optional)
