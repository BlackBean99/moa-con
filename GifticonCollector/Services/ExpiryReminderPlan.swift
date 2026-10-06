import Foundation

struct ReminderCoupon: Sendable {
    let id: UUID
    let brand: String
    let title: String
    let expiryDate: Date?
    let isUsed: Bool
    let needsReview: Bool
}

struct ExpiryReminder: Sendable, Equatable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
    let isLate: Bool
}

enum ExpiryReminderPlan {
    static let prefix = "moacon.expiry."
    static func make(coupons: [ReminderCoupon], daysBefore: Int, now: Date = .now, calendar: Calendar = .current) -> [ExpiryReminder] {
        var result: [ExpiryReminder] = []
        for coupon in coupons.sorted(by: { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }) {
            guard !coupon.isUsed, !coupon.needsReview, let expiry = coupon.expiryDate,
                  calendar.startOfDay(for: expiry) >= calendar.startOfDay(for: now),
                  let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: expiry)),
                  let reminderDay = calendar.date(byAdding: .day, value: -max(daysBefore, 0), to: calendar.startOfDay(for: expiry)),
                  let scheduled = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reminderDay) else { continue }
            let isLate = scheduled <= now
            let date = isLate ? now.addingTimeInterval(60) : scheduled
            guard date < end else { continue }
            result.append(ExpiryReminder(identifier: "\(prefix)\(coupon.id.uuidString).\(Int(expiry.timeIntervalSince1970)).\(daysBefore)",
                title: "\(coupon.brand) 쿠폰 만료", body: "\(coupon.title) · \(expiry.formatted(date: .numeric, time: .omitted))까지",
                fireDate: date, isLate: isLate))
            if result.count == 50 { break }
        }
        return result
    }
}
