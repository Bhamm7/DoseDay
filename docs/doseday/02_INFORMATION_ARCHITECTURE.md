# Information Architecture & Navigation

## Tab Bar (v1)

```
[ Schedule ]  [ Reports ]  [ Protocols ]  [ Tools ]
     📅           📊           💊           🔧
```

---

## Schedule Tab (Default/Home)

The primary interaction surface. Shows a single day's data with integrated calendar navigation.

### Header
- Date display with ◀ ▶ arrows for day navigation
- ▼ chevron to expand/collapse inline calendar
- 📌 pin button to keep calendar expanded by default (user preference)

### Inline Calendar (collapsed by default)
- Month grid with drug color indicators per day
- Adherence shading: green (all taken), yellow (partial), red (missed), gray (future)
- Tap any day → changes Schedule context to that day, collapses calendar (unless pinned)
- "Today" button to snap back to current date

### Day Content (scrollable)
1. **Summary chips**: Drug counts for the day (e.g., "DrugA • 2", "DrugB • 1")
2. **Dose Timeline**: Chronological list of scheduled doses
   - Time, drug name (with color dot), status pill
   - "Mark taken" button for scheduled doses
   - Tap row → DoseEventDetailSheet
3. **Vitals Section**: Weight, BP, HR, glucose entry
4. **Symptoms Section**: Side effects and observations (multiline text)

### DoseEventDetailSheet
- Scheduled time display
- Mark taken (now or custom time)
- Skip with optional reason
- Injection site picker (if route == injection)
- Per-dose notes (optional)

---

## Reports Tab

Data visualization hub with three segments.

### Segmented Control: `Compounds | Vitals | Labs`

### Compounds Segment
- Serum level estimate graph (exponential decay curves)
- Drug multi-select
- Date range picker (7D, 30D, 90D, Custom)
- Lines colored by drug color
- Labeled as "Visual Estimate Only"

### Vitals Segment
- Trend charts for: weight, blood pressure, resting HR, glucose
- Metric toggles
- Date range picker
- Protocol start/end markers (vertical lines)

### Labs Segment
- Bloodwork trends with reference ranges
- Markers: testosterone, estrogen, hematocrit, lipids, liver enzymes, etc.
- Sparse data points connected over time
- "Add Labs" button → navigates to Tools > Labs Entry

---

## Protocols Tab

Medication and protocol management.

### ProtocolListView
- List of protocols with name, date range, status
- Add protocol button → AddProtocolFlow

### ProtocolDetailView
- Protocol info (name, start/end dates)
- Drug list with:
  - Name, color swatch
  - Route, unit
  - Schedule summary (human readable)
  - Half-life
- Edit protocol / set end date
- Add drug button

### AddProtocolFlow (wizard style)
1. Step 1: Protocol name + start date + optional end date
2. Step 2: Add drugs (repeatable)
3. Step 3: Review + Save

### DrugEditorView
- Name, route, unit, color picker
- Schedule type + times configuration
- **Dose calculator** (built-in helper for dosing math)
- Half-life hours
- Reminder settings (on/off, minutes before, sound)

---

## Tools Tab

Standalone utilities and app configuration.

### Tools List
- **Labs Entry**: Bloodwork data entry form (date, values, notes)
- **Reconstitution Calculator**: Powder + BAC water → concentration and dose volume
- **Insights**: AI-generated observations based on adherence, vitals, labs
- **Export Data**: CSV/JSON export for protocols, events, vitals, labs

### Settings Section
- Notification permissions + default reminder settings
- Units preferences (kg/lb, mmol/L vs mg/dL for glucose)
- App info / About
