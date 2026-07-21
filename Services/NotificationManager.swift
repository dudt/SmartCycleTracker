import Foundation
import UserNotifications

/// 思雨经期助手 — 本地来潮提醒服务 (无需付费开发者 Push 权限，纯本地通知)
public struct NotificationManager {
    
    public static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    public static func schedulePeriodReminder(predictedStartDate: Date, isEnabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard isEnabled else { return }

        // 提前 2 天提醒
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -2, to: predictedStartDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "思雨经期提醒"
        content.body = "预计月经将在 2 天后到来，请准备好经期用品，注意保暖与身体休息。"
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "siyu_period_reminder", content: content, trigger: trigger)
        center.add(request)
    }
}
