import SwiftData
import SwiftUI

@main
struct GifticonCollectorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Gifticon.self)
        } catch {
            // A persistent-store failure should be surfaced by the app's error UI in production.
            fatalError("Unable to create the local Gifticon store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { @MainActor in
                appDelegate.photoLibraryService.refreshAuthorizationStatus()
                appDelegate.backgroundScanCoordinator.scheduleProcessingTask()
            }
        }
    }
}
