# Graphs Specs (Swift Charts)

## Graph Hub
Two segments/tabs inside Graphs:
1) Serum estimates
2) Vitals

## Serum Estimate Graph (v1 placeholder OK)
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

### Placeholder math (until real formulas)
- For each dose event, model an exponential decay curve:
  - contribution(t) = doseAmount * 0.5 ^ ((t - doseTime)/halfLifeHours)
- total(t) = sum contributions from events with doseTime <= t
- Sample at fixed interval:
  - 1h sampling for <= 30 days
  - 3h sampling for > 30 days
- This is a "visual estimate" only; label clearly in UI.

## Vitals Graph
### Inputs
- Toggle buttons for metrics:
  - Weight
  - Blood Pressure (systolic & diastolic)
  - Resting HR
  - Blood glucose
- Date range picker

### Output
- Lines or points per metric (default points connected)
- Protocol markers:
  - show small vertical markers/dots at protocol start and protocol end (if exists)
  - marker color can be neutral or use protocol accent; avoid clutter

### Data gaps
- If a day has no value for a selected metric, skip point.

## Performance notes
- Precompute chart series in a view model
- Cache serum samples per drug+range key
