# UI Specs (SwiftUI)

## Design Language
- Clean, readable, schedule-first
- Colors are per-drug; use them as small accents (dots/chips), not full backgrounds
- Accessibility:
  - Support Dynamic Type
  - Color not the only signal: include labels in dose details
  - VoiceOver labels on all interactive elements

---

## Schedule Tab

### Header Bar
```
┌─────────────────────────────────────────┐
│  ◀  April 12, 2026  ▶     ▼     📌     │
└─────────────────────────────────────────┘
```
- **◀ ▶**: Navigate to previous/next day
- **Date**: Tappable, opens date picker
- **▼**: Chevron to expand/collapse inline calendar
- **📌**: Pin button to keep calendar expanded (toggles user preference)

### Inline Calendar (Expandable)
- 7-column month grid
- Each cell:
  - Day number
  - Up to 3 drug color indicators (small dots)
  - "+N" if more than 3 drugs
  - Background shading for adherence:
    - Green tint: all doses taken
    - Yellow tint: partial
    - Red tint: missed doses
    - No tint: future/no data
- Tap day → updates Schedule view to that date
- "Today" pill button when viewing non-current date

### Summary Chips
- Horizontal scroll of chips below header
- Format: "DrugName • count" with drug color dot
- Shows drugs scheduled for the current day

### Dose Timeline
- Vertical list sorted by scheduled time
- Each dose row:
  ```
  ┌─────────────────────────────────────────┐
  │ ● DrugName                    08:00 AM  │
  │   250mg                      [Taken ✓]  │
  │   Left delt                             │
  └─────────────────────────────────────────┘
  ```
  - Color dot matching drug
  - Drug name + dose amount
  - Time
  - Status pill: `Scheduled` / `Taken ✓` / `Skipped`
  - Injection site subtitle (if applicable)
  - Tap → DoseEventDetailSheet

### Vitals Section
- Collapsible section with header "Vitals"
- Fields:
  - Weight (with unit label)
  - Blood pressure (systolic / diastolic)
  - Resting HR
  - Blood glucose (with unit label)
- Show last saved timestamp
- Explicit "Save" button

### Symptoms Section
- Collapsible section with header "Symptoms"
- Fields:
  - Side effects: multiline text
  - Observations: multiline text
- Explicit "Save" button

---

## DoseEventDetailSheet

Modal sheet when tapping a dose row.

### Content
- Drug name + color indicator
- Scheduled time
- Dose amount + unit
- **Actions**:
  - "Mark Taken" button (uses current time)
  - "Taken at..." option (custom time picker)
  - "Skip" button with optional reason field
- **Injection Site** (only if route == injection):
  - Picker: left/right glute, quad, delt, abdomen, other
  - Free text field if "Other" selected
- **Notes**: Optional per-dose note field

---

## Reports Tab

### Segment Control
```
[ Compounds ]  [ Vitals ]  [ Labs ]
```

### Compounds Segment
- Drug selector (multi-select chips)
- Date range picker: 7D | 30D | 90D | Custom
- Swift Charts line graph:
  - X-axis: date/time
  - Y-axis: "Relative Level" (unitless)
  - One line per selected drug, colored by drug color
- Footer disclaimer: "Visual estimate only"

### Vitals Segment
- Metric toggles: Weight, BP, HR, Glucose
- Date range picker
- Swift Charts with:
  - Points connected by lines
  - Multiple Y-axes or normalized scale
  - Vertical rule markers for protocol start/end dates
- Data gaps: skip missing days, don't interpolate

### Labs Segment
- Metric selector (testosterone, hematocrit, etc.)
- Date range picker
- Swift Charts scatter/line:
  - Points at entry dates
  - Reference range bands (shaded regions)
- "Add Labs" button → navigates to Tools > Labs Entry

---

## Protocols Tab

### ProtocolListView
- List rows:
  ```
  ┌─────────────────────────────────────────┐
  │ Protocol Name                           │
  │ Started Mar 1, 2026 • 3 compounds       │
  │ ● ● ●                                   │
  └─────────────────────────────────────────┘
  ```
  - Protocol name
  - Date range / status
  - Drug color dots
- "+" button → AddProtocolFlow

### ProtocolDetailView
- Header: Protocol name, start/end dates, edit button
- Drug list:
  - Color swatch + name
  - Route + unit
  - Schedule summary (e.g., "Daily at 8:00 AM, 8:00 PM")
  - Half-life
  - Tap → DrugEditorView
- "Add Drug" button
- "End Protocol" action

### DrugEditorView
- Name field
- Route picker (oral, injection, other)
- Unit picker (mg, mcg, IU, mL)
- Color picker (preset palette)
- Schedule configuration:
  - Type: Daily | Specific weekdays | Every N days
  - Times of day (add/remove)
  - Dose amount per administration
- **Dose Calculator**: Built-in helper for common calculations
- Half-life hours field
- Reminder settings:
  - Toggle on/off
  - Minutes before (0, 5, 10, 15, 30, 60)
  - Sound toggle

---

## Tools Tab

### Tools List
- **Labs Entry**
  - Date picker (defaults to today)
  - Dynamic form for lab values:
    - Testosterone (ng/dL or nmol/L)
    - Estradiol (pg/mL)
    - Hematocrit (%)
    - Lipid panel (HDL, LDL, Total, Triglycerides)
    - Liver enzymes (AST, ALT)
    - Add custom marker
  - Notes field
  - Save button

- **Reconstitution Calculator**
  - Powder amount (mg or IU)
  - BAC water volume (mL)
  - → Shows concentration (per 0.1mL increments)
  - Desired dose input → volume to inject

- **Insights**
  - AI-generated observations
  - Adherence patterns
  - Vitals trends
  - Lab correlations
  - Refresh button

- **Export Data**
  - Format picker: CSV | JSON
  - Data selection: Protocols, Dose Events, Vitals, Labs
  - Share sheet

### Settings Section
- **Notifications**
  - Permission status + request button
  - Default reminder minutes
  - Sound toggle
  - Test notification button
- **Units**
  - Weight: kg | lb
  - Glucose: mmol/L | mg/dL
  - Lab units (per marker)
- **About**
  - Version
  - Disclaimer text

---

## Injection Site UX

### In DoseEventDetailSheet
- Site picker (simple list):
  - Left Glute / Right Glute
  - Left Quad / Right Quad
  - Left Delt / Right Delt
  - Abdomen Left / Abdomen Right
  - Other (shows text field)
- Selected site shown in dose row subtitle

### Site Rotation (future consideration)
- Track recent sites per drug
- Suggest next site based on rotation
