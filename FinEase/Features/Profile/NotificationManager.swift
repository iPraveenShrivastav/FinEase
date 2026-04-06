import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    
    var isAuthorized: Bool = false
    var isDailyReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "daily_reminder_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "daily_reminder_enabled") }
    }
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
        }
    }
    
    func toggleDailyReminder(enable: Bool) async {
        guard enable else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_expense_reminder"])
            isDailyReminderEnabled = false
            return
        }
        
        let granted = isAuthorized ? true : await requestAuthorization()
        
        if granted {
            scheduleDailyReminder()
            isDailyReminderEnabled = true
        } else {
            isDailyReminderEnabled = false
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time to review your spending!"
        content.body = "Don't forget to log your daily expenses to stay on track."
        content.sound = .default
        
        // Reminder every day at 8:00 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_expense_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            }
        }
    }
}
