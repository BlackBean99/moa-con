import BackgroundTasks
import Foundation
import SwiftData

@MainActor
final class BackgroundScanCoordinator {
    static let taskIdentifier = "com.yourteam.gifticoncollector.scan"

    private let photoLibraryService: PhotoLibraryService
    private var modelContainer: ModelContainer?

    init(photoLibraryService: PhotoLibraryService) {
        self.photoLibraryService = photoLibraryService
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
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
            guard let modelContainer else {
                task.setTaskCompleted(success: false)
                return
            }

            let viewModel = ScanViewModel(
                photoLibraryService: photoLibraryService,
                modelContext: modelContainer.mainContext
            )
            await viewModel.scanAll()
            task.setTaskCompleted(success: viewModel.errorMessage == nil)
            self.scheduleProcessingTask()
        }
    }
}
