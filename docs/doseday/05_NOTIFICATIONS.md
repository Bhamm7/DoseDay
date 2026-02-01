# Notifications

## Requirements
- Use UNUserNotificationCenter
- Ask permission once user enables reminders (or in Settings)
- Schedule notifications for future DoseEvents only
- Reschedule when:
  - drug schedule changes
  - protocol start/end changes
  - user changes reminder settings
  - app launches (light reconciliation)

## ReminderSettings (per drug)
- enabled: Bool
- minutesBefore: Int (0, 5, 10, 15, 30, 60)
- notificationTitleTemplate: String (default: "{drug} reminder")
- notificationBodyTemplate: String (default: "Scheduled at {time}")
- soundEnabled: Bool

## Notification identifier strategy
- "doseevent:{doseEventId}"

## Scheduling logic
For each future DoseEvent with status == scheduled:
- fireAt = scheduledAt - minutesBefore
- create UNCalendarNotificationTrigger from fireAt DateComponents
- content includes drug name and time
- category for quick actions (optional v1.1):
  - Mark Taken
  - Skip

## Safety / UX
- If permission denied, show non-blocking banner in Settings
- Provide "Test notification" button in Settings
