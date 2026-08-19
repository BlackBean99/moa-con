import Photos
import SwiftData
import SwiftUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ScanViewModel

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(
            photoLibraryService: photoLibraryService,
            modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isScanning {
                    ProgressView(value: Double(viewModel.processedCount), total: Double(max(viewModel.totalCount, 1)))
                        .padding(.horizontal)
                    ClayIcon(systemName: "sparkle.magnifyingglass", color: ClayTheme.butter, size: 76)
                    Text("사진을 살펴보고 있어요")
                        .font(.title2.bold())
                        .foregroundStyle(ClayTheme.ink)
                    Text("바코드 후보를 찾거나 OCR 중이에요… \(viewModel.processedCount)/\(viewModel.totalCount)")
                        .foregroundStyle(.secondary)
                    if viewModel.candidateCount > 0 {
                        Text("OCR 대상 후보 \(viewModel.candidateCount)장")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ClayIcon(systemName: "wand.and.stars", color: ClayTheme.lilac, size: 86)
                    Text("사진 라이브러리에서 기프티콘을 찾아 등록합니다.")
                        .multilineTextAlignment(.center)
                    Button("전체 사진 스캔 시작") {
                        Task { await viewModel.scanAll() }
                    }
                    .buttonStyle(ClayPrimaryButtonStyle())
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)
            .background(ClayTheme.canvas.ignoresSafeArea())
            .navigationTitle("기프티콘 스캔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
