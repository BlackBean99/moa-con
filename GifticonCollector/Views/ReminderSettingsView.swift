import SwiftUI
import SwiftData
import UserNotifications

struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var enabled = NotificationService.remindersEnabled
    @State private var days = NotificationService.daysBefore
    @State private var busy = false
    @State private var pendingCount = 0
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("만료 알림", isOn: $enabled).disabled(busy)
                    if enabled {
                        Picker("알림 시점", selection: $days) {
                            Text("3일 전").tag(3); Text("1일 전").tag(1); Text("만료일").tag(0)
                        }.disabled(busy)
                    }
                } footer: { Text("확인한 미사용 쿠폰에 오전 9시 알림을 예약합니다. 만료가 가까운 50개 쿠폰부터 적용합니다.") }
                Section { Text("예약된 알림 \(pendingCount)개") }
                Section { Button("시스템 알림 설정") { openURL(URL(string: UIApplication.openSettingsURLString)!) } }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                if busy { ProgressView("설정 중") }
            }
            .navigationTitle("알림 설정").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
            .task { await refreshCount() }
            .onChange(of: enabled) { _, _ in update() }
            .onChange(of: days) { _, _ in update() }
        }
        .tint(MoaconTheme.accent)
    }
    private func refreshCount() async {
        pendingCount = await UNUserNotificationCenter.current().pendingNotificationRequests().filter { $0.identifier.hasPrefix(ExpiryReminderPlan.prefix) }.count
    }
    private func update() {
        guard !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            if enabled {
                await NotificationService.requestAuthorization()
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                if ![.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) { enabled = false; error = "시스템 설정에서 알림을 허용해 주세요." }
            }
            NotificationService.remindersEnabled = enabled
            NotificationService.daysBefore = days
            if let message = await NotificationService.synchronize(in: context) { error = message }
            await refreshCount()
        }
    }
}
