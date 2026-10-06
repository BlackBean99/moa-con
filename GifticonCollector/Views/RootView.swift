import Photos
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding = false
    @State private var importMessage: String?
    @State private var reminderTask: Task<Void, Never>?
    @StateObject private var photoLibraryService = PhotoLibraryService()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            _hasCompletedOnboarding = AppStorage(wrappedValue: false, "onboarding.uiTest.completed")
        }
        #endif
    }

    private var bypassOnboarding: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
            && !ProcessInfo.processInfo.arguments.contains("--onboarding-testing")
        #else
        false
        #endif
    }

    private var testingColorScheme: ColorScheme? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--ui-testing") && arguments.contains("--dark-appearance") ? .dark : nil
        #else
        return nil
        #endif
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding || bypassOnboarding {
                GifticonListView(photoLibraryService: photoLibraryService, modelContext: modelContext, importMessage: importMessage)
            } else {
                OnboardingView { hasCompletedOnboarding = true }
            }
        }
        .tint(MoaconTheme.accent)
        .preferredColorScheme(testingColorScheme)
        .task { await refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .couponStoreDidChange)) { _ in refreshReminders() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in refreshReminders() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private func refreshReminders() {
        reminderTask?.cancel()
        reminderTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            if let error = await NotificationService.synchronize(in: modelContext) { importMessage = error }
        }
    }

    private func refresh() async {
        photoLibraryService.refreshAuthorizationStatus()
        try? PersistenceService(modelContext: modelContext).migrateLegacyAmountReview()
        await photoLibraryService.preserveAccessibleOriginals(in: modelContext)
        let result = await SharedImportService(modelContext: modelContext).processPending()
        if let message = result.message { importMessage = message }
        refreshReminders()
    }
}
