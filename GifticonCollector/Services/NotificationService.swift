import UserNotifications

enum NotificationService {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func postScanCompleted(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "기프티콘 검색 완료"
        content.body = count > 0 ? "새 기프티콘 \(count)개를 찾았어요." : "새로 찾은 기프티콘이 없어요."
        content.sound = .default
        content.userInfo = ["route": "gifticons"]
        let request = UNNotificationRequest(identifier: "gifticon.scan.complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
