import BackgroundTasks
import Foundation

@MainActor
final class BackgroundScanCoordinator {
    static let taskIdentifier = "com.yourteam.gifticoncollector.scan"

    private let photoLibraryService: PhotoLibraryService

    init(photoLibraryService: PhotoLibraryService) {
        self.photoLibraryService = photoLibraryService
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(processingTask)
        }
    }

    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    func cancelScheduledTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    private func handle(_ task: BGProcessingTask) {
        task.expirationHandler = {
            // TODO: Cancel the active scan task and persist partial progress.
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            _ = photoLibraryService.fetchImageAssets()
            // TODO: Scan only assets changed since the last successful checkpoint.
            task.setTaskCompleted(success: true)
            self.scheduleProcessingTask()
        }
    }
}
