# DoseDay

An iOS app for tracking medication protocols, administrations, serum levels, and vitals.

## Features (v1)

- **Calendar View**: Month-based schedule visualization with drug color indicators
- **Day View**: Timeline of scheduled doses, vitals tracking, daily notes
- **Protocol Management**: Create medication protocols with multiple drugs and schedules
- **Notifications**: Customizable reminders for scheduled doses
- **Graphs**: Estimated serum levels and vitals over time

## Tech Stack

- iOS 17+ / SwiftUI
- SwiftData (local-first storage)
- Swift Charts
- UserNotifications

## Documentation

See `docs/doseday/` for detailed specifications:

| Document | Description |
|----------|-------------|
| `00_PRODUCT_OVERVIEW.md` | Core concepts and non-goals |
| `01_REQUIREMENTS.md` | Must-have and nice-to-have features |
| `02_INFORMATION_ARCHITECTURE.md` | Navigation and view hierarchy |
| `03_DATA_MODEL.md` | SwiftData entities and enums |
| `04_SCHEDULING_ENGINE.md` | Dose event generation logic |
| `05_NOTIFICATIONS.md` | Reminder system specs |
| `06_UI_SPECS.md` | SwiftUI component details |
| `07_GRAPHS_SPECS.md` | Charts implementation |
| `08_STORAGE_SYNC.md` | Data persistence and export |
| `09_ANALYTICS_PRIVACY.md` | Privacy and safety |
| `10_TESTING_QA.md` | Test strategy |

## Getting Started

1. See `IMPLEMENTATION_PLAN.md` for phased build order
2. Track progress with `TODO.md`

## Disclaimer

This app is for personal tracking only. It does not provide medical advice.
