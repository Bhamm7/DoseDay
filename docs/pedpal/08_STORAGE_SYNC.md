# Storage & Sync

## v1: Local-only
- SwiftData as primary store
- Migrations: keep models stable; add fields with defaults
- Backups: optional export to JSON/CSV from Settings

## v1.1+: Optional iCloud Sync
- SwiftData + CloudKit
- Consider:
  - deterministic IDs
  - conflict resolution for DailyVitals/DailyNote (prefer latest updatedAt)

## Export (optional)
- CSV export:
  - DoseEvents (scheduledAt, status, takenAt, drug, protocol, injectionSite)
  - DailyVitals
  - DailyNotes
- JSON export for full backup

## Privacy
- All data stored on-device by default
- No analytics by default; if added later, make opt-in
