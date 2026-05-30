import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDeadlineReminder(for task: DoItem) {
        guard let deadline = task.deadline, deadline > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "任务即将截止"
        content.body = task.name
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: deadline) ?? deadline
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "deadline-\(task.id)", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleEveningCheck() {
        let content = UNMutableNotificationContent()
        content.title = "今日回顾"
        content.body = "还有未完成的任务，别忘了处理哦"
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "evening-check", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleHabitReminder(for habit: DoItem) {
        guard let reminderTime = habit.reminderTime else { return }
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "该打卡了！坚持就是胜利"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "habit-\(habit.id)", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(for identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
