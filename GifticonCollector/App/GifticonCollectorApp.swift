import SwiftData
import SwiftUI

@main
struct GifticonCollectorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer?
    private let modelContainerError: String?

    init() {
        do {
            modelContainer = try ModelContainer(for: Gifticon.self)
            modelContainerError = nil
        } catch {
            // Do not terminate the process during launch. A store can fail to open after a
            // schema change or when the device store is temporarily unavailable.
            modelContainer = nil
            modelContainerError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootView()
                    .modelContainer(modelContainer)
            } else {
                StoreUnavailableView(message: modelContainerError ?? "알 수 없는 저장소 오류")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, modelContainer != nil else { return }
            Task { @MainActor in
                appDelegate.photoLibraryService.refreshAuthorizationStatus()
                appDelegate.backgroundScanCoordinator.scheduleProcessingTask()
            }
        }
    }
}

private struct StoreUnavailableView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("기프트콘 저장소를 열 수 없습니다", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("앱을 종료한 후 다시 실행해 주세요. 문제가 계속되면 앱을 재설치하기 전에 저장된 기프트콘 데이터를 백업할 수 있는지 확인해 주세요.")
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
