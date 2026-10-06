import Foundation
import SwiftData
import UserNotifications

extension Notification.Name {
    static let couponStoreDidChange = Notification.Name("moacon.couponStoreDidChange")
}

@MainActor
enum NotificationService {
    private static var queued: Task<String?, Never>?
    static var remindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "reminders.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "reminders.enabled") }
    }
    static var daysBefore: Int {
        get { UserDefaults.standard.object(forKey: "reminders.daysBefore") as? Int ?? 1 }
        set { UserDefaults.standard.set(newValue, forKey: "reminders.daysBefore") }
    }

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func synchronize(in context: ModelContext) async -> String? {
        let coupons: [ReminderCoupon]
        do {
            coupons = try context.fetch(FetchDescriptor<Gifticon>()).map {
                ReminderCoupon(id: $0.id, brand: $0.brand, title: $0.title, expiryDate: $0.expiryDate, isUsed: $0.isUsed, needsReview: $0.needsReview)
            }
        } catch { return "만료 알림 정보를 불러오지 못했어요." }
        let previous = queued
        let enabled = remindersEnabled
        let days = daysBefore
        let task = Task { @MainActor in
            // Serialize rebuilds: an older add must finish before newer deletion/settings apply.
            _ = await previous?.value
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let owned = pending.filter { $0.identifier.hasPrefix(ExpiryReminderPlan.prefix) }
            let settings = await center.notificationSettings()
            guard enabled, [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
                center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
                let delivered = await center.deliveredNotifications()
                center.removeDeliveredNotifications(withIdentifiers: delivered.map(\.request.identifier).filter { $0.hasPrefix(ExpiryReminderPlan.prefix) })
                return enabled ? "만료 알림을 받으려면 시스템 알림 권한을 허용해 주세요." : nil
            }
            let plan = ExpiryReminderPlan.make(coupons: coupons, daysBefore: days)
            var scheduled = Set(UserDefaults.standard.stringArray(forKey: "reminders.scheduledIdentifiers") ?? [])
            let existing = Dictionary(uniqueKeysWithValues: owned.map { ($0.identifier, $0) })
            var requests: [UNNotificationRequest] = []
            for reminder in plan {
                if reminder.isLate, scheduled.contains(reminder.identifier) {
                    if let request = existing[reminder.identifier] { requests.append(request) }
                    continue
                }
                let content = UNMutableNotificationContent()
                content.title = reminder.title; content.body = reminder.body; content.sound = .default
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                requests.append(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
            }
            let wanted = Set(requests.map(\.identifier))
            center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier).filter { !wanted.contains($0) })
            let valid = Set(plan.map(\.identifier))
            let delivered = await center.deliveredNotifications()
            center.removeDeliveredNotifications(withIdentifiers: delivered.map(\.request.identifier).filter {
                $0.hasPrefix(ExpiryReminderPlan.prefix) && !valid.contains($0)
            })
            do {
                for request in requests {
                    try await center.add(request)
                    scheduled.insert(request.identifier)
                }
                // Retain only current coupon identities; metadata edits keep the same identity.
                UserDefaults.standard.set(Array(scheduled.intersection(valid)), forKey: "reminders.scheduledIdentifiers")
                return nil
            } catch { return "일부 만료 알림을 예약하지 못했어요. 다시 시도해 주세요." }
        }
        queued = task
        return await task.value
    }

    static func postScanCompleted(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "쿠폰 찾기 완료"
        content.body = "새 쿠폰 \(count)개를 찾았어요."
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "gifticon.scan.complete", content: content, trigger: nil))
    }
}
