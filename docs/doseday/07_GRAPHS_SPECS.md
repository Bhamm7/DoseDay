# Stats / Graphs Specs (Swift Charts)

## Stats Hub
Three segments/tabs inside Stats:
1) Overview
2) Compare
3) Labs

## Overview
### Purpose
- Give the user a fast read on what changed recently.
- Surface outliers and missed items before the user opens the deeper analysis view.

### Cards / sections
- Adherence summary
- Serum summary for selected compounds
- Latest vitals snapshot
- Recent abnormal bloodwork markers
- Recent symptom flare-ups

### Interactions
- Tap a summary card to open Compare with the relevant filters pre-applied.

## Compare

### Layout
- Fixed controls at top:
  - date range picker (7D, 30D, 90D, Custom)
  - active protocol / compound multi-select
  - metric filters
  - symptom filters
  - lab marker filters
  - "Out of range only" toggle for labs
  - "Show reference bands" toggle
- Scrollable chart stack below:
  1. Serum
  2. Vitals
  3. Labs
  4. Symptoms lane

### Core principle
- Do not plot serum, vitals, and raw lab values on the same y-axis.
- All panels share the same x-axis time window but keep independent y-axes.
- Correlation comes from vertical alignment in time, not by forcing unlike units into one scale.

### Shared interactions
- Linked scrubber / crosshair across every panel
- Protocol markers shown in all panels as light vertical rules
- Tap data point -> open detail / source record
- Saved compare views (future): allow users to store common filter combinations

## Serum Panel
### Inputs
- One or multiple selected drugs
- Date range picker (7D, 30D, 90D, Custom)
- For each selected drug:
  - use DoseEvents in range
  - halfLifeHours must exist; if missing, show "Half-life not set" message

### Output
- Line per drug (colored by drug.colorHex)
- Y-axis: "Relative level" (unitless in v1)
- X-axis: date/time
- Optional adherence overlay should remain separate from serum level itself unless visually distinct enough to avoid confusion.

### Placeholder math (until real formulas)
- For each dose event, model an exponential decay curve:
  - contribution(t) = doseAmount * 0.5 ^ ((t - doseTime)/halfLifeHours)
- total(t) = sum contributions from events with doseTime <= t
- Sample at fixed interval:
  - 1h sampling for <= 30 days
  - 3h sampling for > 30 days
- This is a "visual estimate" only; label clearly in UI.

## Vitals Panel
### Inputs
- Toggle buttons for metrics:
  - Weight
  - Blood Pressure (systolic & diastolic)
  - Resting HR
  - Blood glucose
- Date range picker

### Output
- Separate charts by metric family unless units naturally belong together:
  - Weight alone
  - Blood Pressure with systolic + diastolic together
  - Resting HR alone
  - Blood glucose alone
- Lines or points per metric (default points connected)
- Protocol markers:
  - show small vertical markers/dots at protocol start and protocol end (if exists)
  - marker color can be neutral or use protocol accent; avoid clutter

### Data gaps
- If a day has no value for a selected metric, skip point.

## Labs Panel
### Inputs
- Searchable lab marker selector
- Optional favorites / pinned markers
- "Out of range only" toggle
- Optional grouping by report / panel

### Output
- Default raw mode:
  - one mini-chart per selected lab marker
  - each chart uses that marker's native units
  - show shaded reference range band when low/high bounds are available
  - out-of-range points should be visually flagged
- Report annotations:
  - multiple markers from the same blood draw should align vertically on the same collection date

### Why not overlay raw labs together?
- Lab values may use incompatible units and scales.
- Visual comparison should come from synchronized time position, not a shared raw-value axis.

### Future optional mode: Normalized Compare
- Explicitly optional and not default
- Labs can be transformed relative to reference range:
  - below range
  - within range
  - above range
  - or normalized percent-of-range
- Useful for pattern comparison, but must be labeled clearly as transformed data

## Symptoms Lane
### Inputs
- Symptom tag filters

### Output
- Event timeline or lane view
- Symptom severity encoded by point size or intensity
- Symptoms should sit below the numeric charts so they read as contextual events

## Labs View
### Purpose
- Dedicated report and marker management surface inside the Stats tab

### Main sections
- Report list grouped by collection date
- Quick actions:
  - Add manually
  - Import PDF / photo / CSV
- Report detail:
  - source
  - collected date
  - file attachment metadata
  - marker list with abnormal flags
  - "Compare selected markers" action

## Performance notes
- Precompute chart series in a view model
- Cache serum samples per drug+range key
- Precompute lab series per marker+range key
- Keep report list and compare-state filters separate so large lab histories do not rerender the entire screen
