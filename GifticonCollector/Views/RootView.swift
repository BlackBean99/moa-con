import Photos
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var photoLibraryService = PhotoLibraryService()

    var body: some View {
        Group {
            switch photoLibraryService.authorizationStatus {
            case .authorized, .limited:
                GifticonListView(photoLibraryService: photoLibraryService, modelContext: modelContext)
            case .notDetermined:
                PermissionPreflightView(photoLibraryService: photoLibraryService)
            case .denied, .restricted:
                ManualImportView(photoLibraryService: photoLibraryService)
            @unknown default:
                ManualImportView(photoLibraryService: photoLibraryService)
            }
        }
        .task {
            photoLibraryService.refreshAuthorizationStatus()
        }
    }
}

struct PermissionPreflightView: View {
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("기프티콘을 자동으로 찾아드려요")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("사진은 이 기기 안에서만 분석됩니다. 전체 사진 접근을 허용하면 새로 저장한 기프티콘도 자동으로 찾아 만료일을 놓치지 않도록 관리할 수 있습니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                isRequesting = true
                Task {
                    _ = await photoLibraryService.requestReadWriteAuthorization()
                    isRequesting = false
                }
            } label: {
                Text("사진 접근 허용")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .accessibilityHint("기프트콘 이미지를 자동으로 인식하기 위해 사진 라이브러리 접근 권한을 요청합니다")
        }
        .padding(24)
    }
}
