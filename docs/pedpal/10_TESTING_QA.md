# Testing & QA

## Unit tests
- Scheduling engine:
  - daily schedule generates correct times
  - weekdays schedule generates only specified weekdays
  - every-N-days schedule aligns with startDate
  - editing schedule preserves past taken events
- Serum estimate sampler:
  - produces monotonic decay between doses
  - multiple doses sum properly

## UI tests (smoke)
- Create protocol with 2 drugs
- Verify calendar shows dots
- Tap day -> day view shows timeline entries
- Mark dose taken -> status updates and persists
- Add vitals -> appears on Vitals graph
- Enable notifications -> schedules at least one upcoming notification

## Manual QA checklist
- Timezone/DST boundary day behavior
- Large font / dynamic type layout
- Color contrast (light/dark mode)
- Performance: scrolling month to month
