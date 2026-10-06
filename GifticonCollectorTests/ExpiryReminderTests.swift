import XCTest
@testable import GifticonCollector

final class ExpiryReminderTests: XCTestCase {
    private var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 9 * 3600)!; return c }
    private func day(_ value: Int, hour: Int = 0) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: value, hour: hour))! }
    private func coupon(expiry: Date?, used: Bool = false, review: Bool = false) -> ReminderCoupon {
        ReminderCoupon(id: UUID(), brand: "카페", title: "교환권", expiryDate: expiry, isUsed: used, needsReview: review)
    }
    func testOnlyConfirmedUnusedUnexpiredCouponsAreScheduled() {
        let coupons = [coupon(expiry: day(10)), coupon(expiry: day(10), used: true), coupon(expiry: day(10), review: true), coupon(expiry: day(5)), coupon(expiry: nil)]
        let plan = ExpiryReminderPlan.make(coupons: coupons, daysBefore: 1, now: day(6), calendar: calendar)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.fireDate, day(9, hour: 9))
    }
    func testFinalDayIsUsableAndLateReminderDoesNotCrossExpiry() {
        let valid = ExpiryReminderPlan.make(coupons: [coupon(expiry: day(6))], daysBefore: 3, now: day(6, hour: 12), calendar: calendar)
        XCTAssertEqual(valid.first?.fireDate, day(6, hour: 12).addingTimeInterval(60))
        XCTAssertTrue(valid.first?.isLate ?? false)
        XCTAssertTrue(ExpiryReminderPlan.make(coupons: [coupon(expiry: day(6))], daysBefore: 1, now: day(7), calendar: calendar).isEmpty)
    }
    func testDateEditChangesIdentityAndUseOrDeleteRemovesPlan() {
        var original = coupon(expiry: day(10))
        let first = ExpiryReminderPlan.make(coupons: [original], daysBefore: 1, now: day(6), calendar: calendar)
        original = ReminderCoupon(id: original.id, brand: original.brand, title: original.title, expiryDate: day(12), isUsed: false, needsReview: false)
        let second = ExpiryReminderPlan.make(coupons: [original], daysBefore: 1, now: day(6), calendar: calendar)
        XCTAssertNotEqual(first.first?.identifier, second.first?.identifier)
        XCTAssertTrue(ExpiryReminderPlan.make(coupons: [], daysBefore: 1, now: day(6), calendar: calendar).isEmpty)
        XCTAssertTrue(ExpiryReminderPlan.make(coupons: [coupon(expiry: day(12), used: true)], daysBefore: 1, now: day(6), calendar: calendar).isEmpty)
    }
    func testClosestFiftyAreScheduled() {
        let coupons = (8...70).reversed().map { coupon(expiry: calendar.date(byAdding: .day, value: $0, to: day(6))) }
        let plan = ExpiryReminderPlan.make(coupons: coupons, daysBefore: 1, now: day(6), calendar: calendar)
        XCTAssertEqual(plan.count, 50)
        XCTAssertLessThan(plan.first!.fireDate, plan.last!.fireDate)
    }
}
