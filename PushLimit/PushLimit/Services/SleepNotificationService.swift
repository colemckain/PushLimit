import Foundation
import UserNotifications

/// Daily bedtime and wake-up reminders based on the user's sleep schedule.
final class SleepNotificationService {
    static let shared = SleepNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let bedtimeId = "sleep_bedtime"
    private let wakeId = "sleep_wakeup"

    private init() {}

    func refreshScheduledNotifications(schedule: SleepSchedule?, streak: Int = 0) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }

            let sleepIds = requests
                .map(\.identifier)
                .filter { $0 == self.bedtimeId || $0 == self.wakeId }
            self.center.removePendingNotificationRequests(withIdentifiers: sleepIds)

            guard let schedule else {
                DebugLog.log("ℹ️ Sleep notifications skipped — no schedule set")
                return
            }

            self.scheduleDaily(
                id: self.bedtimeId,
                hour: schedule.bedtimeHour,
                minute: schedule.bedtimeMinute,
                content: PushLimitNotificationCopy.bedtime(streak: streak)
            )
            self.scheduleDaily(
                id: self.wakeId,
                hour: schedule.wakeHour,
                minute: schedule.wakeMinute,
                content: PushLimitNotificationCopy.wake(streak: streak)
            )

            DebugLog.log("✅ Sleep notifications scheduled — bed \(schedule.formattedBedtime), wake \(schedule.formattedWakeTime)")
        }
    }

    func removeSleepNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [bedtimeId, wakeId])
    }

    func testBedtimeNotification(streak: Int = 0) {
        scheduleImmediateTest(
            id: "test_sleep_bedtime_\(UUID().uuidString)",
            content: PushLimitNotificationCopy.bedtime(streak: streak)
        )
    }

    func testWakeNotification(streak: Int = 0) {
        scheduleImmediateTest(
            id: "test_sleep_wake_\(UUID().uuidString)",
            content: PushLimitNotificationCopy.wake(streak: streak)
        )
    }

    private func scheduleDaily(
        id: String,
        hour: Int,
        minute: Int,
        content: (title: String, body: String)
    ) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)

        center.add(request) { error in
            if let error {
                DebugLog.log("❌ Error scheduling \(id): \(error)")
            }
        }
    }

    private func scheduleImmediateTest(id: String, content: (title: String, body: String)) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)

        center.add(request) { error in
            if let error {
                DebugLog.log("❌ Error scheduling \(id): \(error)")
            } else {
                DebugLog.log("✅ Scheduled \(id)")
            }
        }
    }
}
