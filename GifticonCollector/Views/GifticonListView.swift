import Photos
import SwiftData
import SwiftUI

struct GifticonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gifticon.createdAt, order: .reverse) private var gifticons: [Gifticon]
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @StateObject private var scanViewModel: ScanViewModel

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        self.photoLibraryService = photoLibraryService
        _scanViewModel = StateObject(wrappedValue: ScanViewModel(photoLibraryService: photoLibraryService, modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            List {
                if scanViewModel.isScanning {
                    ScanProgressBanner(viewModel: scanViewModel)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if photoLibraryService.authorizationStatus == .limited {
                    LimitedAccessBanner(photoLibraryService: photoLibraryService)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if gifticons.isEmpty {
                    ContentUnavailableView(
                        "아직 기프티콘이 없어요",
                        systemImage: "gift",
                        description: Text("사진을 스캔하면 인식된 기프티콘이 여기에 저장됩니다.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(gifticons) { gifticon in
                        NavigationLink {
                            GifticonDetailView(gifticon: gifticon, photoLibraryService: photoLibraryService)
                        } label: {
                            GifticonRow(gifticon: gifticon, photoLibraryService: photoLibraryService)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try? PersistenceService(modelContext: modelContext).delete(gifticon)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(ClayTheme.canvas)
            .navigationTitle("내 기프티콘")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await scanViewModel.scanAll() }
                    } label: {
                        ClayIcon(systemName: "wand.and.stars", color: ClayTheme.butter, size: 38)
                    }
                    .accessibilityLabel("사진에서 기프트콘 찾기")
                }
            }
        }
    }
}

private struct ScanProgressBanner: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("사진을 백그라운드에서 검색 중이에요", systemImage: "sparkle.magnifyingglass")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(viewModel.processedCount), total: Double(max(viewModel.totalCount, 1)))
            Text("화면을 계속 사용할 수 있습니다 · \(viewModel.processedCount)/\(viewModel.totalCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .clayCard(ClayTheme.butter, radius: 22)
        .padding(.horizontal)
    }
}

private struct LimitedAccessBanner: View {
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @State private var isPresentingLimitedPicker = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("선택한 사진만 보고 있어요").font(.headline)
                Text("더 많은 기프트콘을 자동으로 찾으려면 사진을 추가로 선택해 주세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("더 많은 사진 선택") {
                    isPresentingLimitedPicker = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
        .accessibilityElement(children: .contain)
        .background {
            LimitedLibraryPickerPresenter(
                photoLibraryService: photoLibraryService,
                isPresented: $isPresentingLimitedPicker
            )
        }
    }
}

private struct LimitedLibraryPickerPresenter: UIViewControllerRepresentable {
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard isPresented else { return }
        photoLibraryService.presentLimitedLibraryPicker(from: controller)
        DispatchQueue.main.async {
            isPresented = false
        }
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {}
}

private struct GifticonRow: View {
    @Environment(\.modelContext) private var modelContext
    let gifticon: Gifticon
    let photoLibraryService: PhotoLibraryService

    var body: some View {
        HStack(spacing: 12) {
            GifticonPhotoView(gifticon: gifticon, photoLibraryService: photoLibraryService, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(gifticon.brand).font(.headline)
                Text(gifticon.title).foregroundStyle(.secondary)
                if let expiryDate = gifticon.expiryDate {
                    Text("유효기간 \(expiryDate, format: .dateTime.year().month().day())")
                        .font(.caption)
                        .foregroundStyle(expiryDate < .now ? .red : .secondary)
                }
            }
            Spacer()
            Button {
                do {
                    gifticon.isUsed.toggle()
                    try modelContext.save()
                } catch {
                    // TODO: Present a user-visible persistence error.
                }
            } label: {
                ClayIcon(systemName: gifticon.isUsed ? "arrow.uturn.backward" : "checkmark", color: gifticon.isUsed ? ClayTheme.mint : ClayTheme.butter, size: 38)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(gifticon.isUsed ? "사용 처리 취소" : "사용 완료 처리")
        }
        .padding(12)
        .clayCard(gifticon.isUsed ? ClayTheme.mint.opacity(0.55) : .white, radius: 22)
        .padding(.vertical, 5)
    }
}

private struct GifticonPhotoView: View {
    let gifticon: Gifticon
    let photoLibraryService: PhotoLibraryService
    let size: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "gift.fill").foregroundStyle(.orange) }
        }
        .frame(width: size, height: size)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .clipped()
        .task {
            if gifticon.assetLocalIdentifier.hasPrefix("shared:") {
                image = try? photoLibraryService.loadSharedUIImage(filename: String(gifticon.assetLocalIdentifier.dropFirst("shared:".count)))
                return
            }
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [gifticon.assetLocalIdentifier], options: nil).firstObject else { return }
            image = try? await photoLibraryService.loadUIImage(for: asset, targetSize: CGSize(width: size * 3, height: size * 3))
        }
        .accessibilityLabel("\(gifticon.brand) 기프트콘 이미지")
    }
}
