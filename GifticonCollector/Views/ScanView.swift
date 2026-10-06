import Photos
import SwiftData
import SwiftUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoLibraryService: PhotoLibraryService
    @StateObject private var viewModel: ScanViewModel
    @State private var task: Task<Void, Never>?

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        self.photoLibraryService = photoLibraryService
        _viewModel = StateObject(wrappedValue: ScanViewModel(
            photoLibraryService: photoLibraryService, modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isScanning {
                    Section(viewModel.phaseTitle) {
                        ProgressView(value: Double(viewModel.processedCount), total: Double(max(viewModel.totalCount, 1)))
                        Text("\(viewModel.processedCount)/\(viewModel.totalCount)").monospacedDigit()
                        Button("중단") { task?.cancel() }
                    }
                } else {
                    Button("자동 찾기", systemImage: "photo.badge.magnifyingglass") {
                        task = Task {
                            if photoLibraryService.authorizationStatus == .notDetermined {
                                _ = await photoLibraryService.requestReadWriteAuthorization()
                            }
                            await viewModel.scanAll()
                        }
                    }
                }
                if let result = viewModel.resultMessage { Text(result) }
                if let error = viewModel.errorMessage { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("자동 찾기")
            .navigationBarTitleDisplayMode(.inline)
            .tint(MoaconTheme.accent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
            .onDisappear { task?.cancel() }
        }
    }
}
