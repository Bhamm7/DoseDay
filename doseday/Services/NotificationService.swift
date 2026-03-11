import Foundation
import UserNotifications

struct NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Surfaced via authorizationStatus in Settings
        }
    }

    var authorizationStatus: UNAuthorizationStatus {
        get async {
            await center.notificationSettings().authorizationStatus
        }
    }

    func schedule(for event: DoseEvent) {
        guard let drug = event.drug else { return }
        let reminder = drug.reminder
        guard reminder.enabled, event.status == .scheduled else { return }
        let fireDate = event.scheduledAt.addingTimeInterval(Double(-reminder.minutesBefore) * 60)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(drug.name) reminder"
        content.body = "Scheduled at \(event.scheduledAt.formatted(.dateTime.hour().minute()))"
        content.sound = reminder.soundEnabled ? .default : nil

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "doseevent:\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancel(for event: DoseEvent) {
        center.removePendingNotificationRequests(withIdentifiers: ["doseevent:\(event.id.uuidString)"])
    }

    func reconcile(events: [DoseEvent]) {
        center.removeAllPendingNotificationRequests()
        for event in events where event.status == .scheduled && event.scheduledAt > Date() {
            schedule(for: event)
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "DoseDay Test"
        content.body = "Notifications are working!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test:\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
