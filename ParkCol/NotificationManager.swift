import UserNotifications
import Foundation

// Set as UNUserNotificationCenter.delegate in ParkColApp.init() so banners
// appear even when the app is in the foreground.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private override init() { super.init() }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

enum NotificationManager {

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleReminders(for ticket: ParkingTicket) {
        guard let endTime = ticket.expectedEndTime else { return }
        let center    = UNUserNotificationCenter.current()
        let isSpanish = UserDefaults.standard.string(forKey: "appLanguage") == "Español"
        let name      = ticket.customerFullName
        let vehicle   = ticket.vehicle
        let now       = Date()

        // 15-minute warning
        let reminderTime = endTime.addingTimeInterval(-15 * 60)
        if reminderTime > now {
            let content   = UNMutableNotificationContent()
            content.title = isSpanish ? "Recordatorio de Parqueo" : "Parking Reminder"
            content.body  = isSpanish
                ? "\(name) · \(vehicle): 15 minutos restantes"
                : "\(name) · \(vehicle): 15 minutes remaining"
            content.sound = .default
            schedule(id: reminderID(ticket), content: content, at: reminderTime, center: center)
        }

        // Expiry
        if endTime > now {
            let content   = UNMutableNotificationContent()
            content.title = isSpanish ? "Parqueo Vencido" : "Parking Expired"
            content.body  = isSpanish
                ? "\(name) · \(vehicle): el tiempo de parqueo ha vencido"
                : "\(name) · \(vehicle): parking time has expired"
            content.sound = .default
            schedule(id: expiredID(ticket), content: content, at: endTime, center: center)
        }
    }

    static func cancelReminders(for ticket: ParkingTicket) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID(ticket), expiredID(ticket)])
    }

    // MARK: - Private helpers

    private static func schedule(id: String, content: UNMutableNotificationContent,
                                  at date: Date, center: UNUserNotificationCenter) {
        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static func reminderID(_ t: ParkingTicket) -> String { "parkcol-\(t.id)-reminder" }
    private static func expiredID(_ t: ParkingTicket)  -> String { "parkcol-\(t.id)-expired" }
}
