# Requirements (v1)

## Must-have features
1. Protocol creation
   - Add a protocol (name, start date, optional end date)
   - Add one or more drugs to protocol
   - Each drug:
     - name (string)
     - route (oral/injection/other)
     - unit (mg, mcg, IU, mL, etc)
     - half-life (hours) for future serum estimation graph
     - color (user-picked)
     - schedule definition (see Scheduling Engine doc)
2. Calendar view
   - Month view grid
   - Each day shows drug color indicators (dots/stacked chips)
   - Tap day opens Day view
3. Day view
   - Expandable “timeline” for the day (chronological)
   - Items include scheduled administrations and completion status
   - Record completion + optional injection site (if route == injection)
   - Vitals section (weight, BP sys/dia, resting HR, blood glucose)
   - Notes section (side effects + observations)
4. Notifications
   - Opt-in reminders for scheduled administrations
   - Support per-drug reminder settings (on/off, minutes before, sound)
5. Graphs
   - Serum estimate graph per drug (placeholder math ok; engine pluggable)
   - Vitals graph with metric toggles and protocol start/end markers

## Should-have (nice to have if time)
- Quick-add vitals from Day view
- Drug search suggestions (local list only)
- Calendar filters (by protocol, by drug)
- Export to CSV (protocols, events, vitals, notes)

## Constraints / UX rules
- Local-first: app works offline
- Fast calendar scrolling
- Color accessibility: ensure enough contrast + add labels in details views
- Minimal friction: one-tap “Mark as taken” from Day view

## Acceptance criteria
- User can create a protocol with 2 drugs, see them on calendar, get notifications, mark doses as completed, record vitals/notes, and view both graphs with correct data wiring.
