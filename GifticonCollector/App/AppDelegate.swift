import BackgroundTasks
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    let photoLibraryService = PhotoLibraryService()
    lazy var backgroundScanCoordinator = BackgroundScanCoordinator(
        photoLibraryService: photoLibraryService
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        backgroundScanCoordinator.registerBackgroundTask()
        Task { await NotificationService.requestAuthorization() }
        return true
    }
}
