import SwiftData
import SwiftUI
import UIKit

@main
struct GifticonCollectorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer?
    private let modelContainerError: String?

    init() {
        do {
            let container: ModelContainer
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                try Self.seedPreview(container)
            } else { container = try ModelContainer(for: Gifticon.self) }
            #else
            container = try ModelContainer(for: Gifticon.self)
            #endif
            modelContainer = container
            modelContainerError = nil
            appDelegate.backgroundScanCoordinator.configure(modelContainer: container)
        } catch {
            // Do not terminate the process during launch. A store can fail to open after a
            // schema change or when the device store is temporarily unavailable.
            modelContainer = nil
            modelContainerError = error.localizedDescription
        }
    }

    #if DEBUG
    @MainActor
    private static func seedPreview(_ container: ModelContainer) throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 700)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 700))
            ("테스트 쿠폰 · 사용 불가\n스타벅스\n아메리카노 Tall\n유효기간 2026.12.31" as NSString).draw(in: CGRect(x: 40, y: 60, width: 520, height: 400), withAttributes: [.font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.black])
        }
        let filename = try SharedImageInbox.enqueue(imageData: image.jpegData(compressionQuality: 0.9)!)
        try SharedImageInbox.archive(SharedImageInbox.url(for: filename)!)
        let service = PersistenceService(modelContext: container.mainContext)
        for (barcode, brand, title, review, expiry) in [
            ("DEMO-A", "스타벅스", "아메리카노 Tall", false, Date.now.addingTimeInterval(3 * 86400)),
            ("DEMO-B", "확인할 바코드", "멤버십 카드", true, Date.now.addingTimeInterval(30 * 86400)),
            ("DEMO-C", "이디야", "카페라테", false, Date.now.addingTimeInterval(-86400))
        ] {
            _ = try service.save(parsed: ParsedGifticon(brand: brand, title: title, barcodeNumber: barcode, expiryDate: expiry, amount: 5000, confidence: 0.9, needsReview: review), assetLocalIdentifier: "shared:\(filename)")
        }
    }
    #endif

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
