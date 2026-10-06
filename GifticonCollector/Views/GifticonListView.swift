import Photos
import SwiftData
import SwiftUI

struct GifticonListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gifticon.createdAt, order: .reverse) private var gifticons: [Gifticon]
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @StateObject private var scanViewModel: ScanViewModel

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        self.photoLibraryService = photoLibraryService
        _scanViewModel = StateObject(wrappedValue: ScanViewModel(photoLibraryService: photoLibraryService, modelContext: modelContext))
    }

    @State private var scanTask: Task<Void, Never>?
    @State private var searchText = ""
    @State private var filter = WalletFilter.available
    @State private var showImport = false
    @State private var deletion: Gifticon?
    @State private var errorMessage: String?

    private var visibleGifticons: [Gifticon] {
        gifticons.filter { filter.includes($0) }
            .filter { searchText.isEmpty || "\($0.brand) \($0.title)".localizedCaseInsensitiveContains(searchText) }
            .sorted {
                if filter == .available { return ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
                return $0.createdAt > $1.createdAt
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("모아두고, 제때 쓰세요.").font(.title2.bold()).foregroundStyle(ClayTheme.ink)
                        Text("쓸 수 있는 쿠폰 \(gifticons.filter { WalletFilter.available.includes($0) }.count)개 · 만료 가까운 순")
                            .font(.subheadline).foregroundStyle(ClayTheme.mutedInk)
                        let actionsLayout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                            : AnyLayout(HStackLayout(spacing: 12))
                        actionsLayout {
                            Button { showImport = true } label: { Label("사진 추가", systemImage: "plus") }
                                .buttonStyle(ClayPrimaryButtonStyle())
                            Button {
                                scanTask = Task {
                                    if photoLibraryService.authorizationStatus == .notDetermined {
                                        _ = await photoLibraryService.requestReadWriteAuthorization()
                                    }
                                    if [.authorized, .limited].contains(photoLibraryService.authorizationStatus) {
                                        await scanViewModel.scanAll()
                                    } else {
                                        errorMessage = "자동 찾기는 사진 접근 권한이 필요해요. 사진 추가는 권한 없이 사용할 수 있습니다."
                                    }
                                }
                            } label: { Label("자동 찾기", systemImage: "sparkle.magnifyingglass") }
                                .buttonStyle(.bordered).disabled(scanViewModel.isScanning)
                        }
                        Text("사진은 이 기기에서 분석해요. 선택한 원본은 쿠폰과 함께 보관합니다.")
                            .font(.caption).foregroundStyle(ClayTheme.mutedInk)
                    }
                    .padding(.vertical, 8)
                }.listRowBackground(Color.clear)
                if filter != .review {
                    let reviewCount = gifticons.filter(\.needsReview).count
                    if reviewCount > 0 {
                        Button { filter = .review } label: {
                            Label("확인할 바코드 \(reviewCount)개 · 원본 확인하기", systemImage: "questionmark.circle")
                        }.listRowBackground(ClayTheme.butter.opacity(0.25))
                    }
                }
                if scanViewModel.isScanning {
                    ScanProgressBanner(viewModel: scanViewModel).listRowBackground(Color.clear)
                    Button("중단") { scanTask?.cancel() }.listRowBackground(Color.clear)
                }
                if let result = scanViewModel.resultMessage {
                    Label(result, systemImage: "checkmark.circle").font(.subheadline)
                        .listRowBackground(ClayTheme.mint.opacity(0.3))
                }
                if let error = scanViewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
                if photoLibraryService.authorizationStatus == .limited {
                    LimitedAccessBanner(photoLibraryService: photoLibraryService)
                        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
                Section {
                    if dynamicTypeSize.isAccessibilitySize {
                        Picker("쿠폰 상태", selection: $filter) {
                            ForEach(WalletFilter.allCases) { value in Text(value.rawValue).tag(value) }
                        }.pickerStyle(.menu).listRowBackground(Color.clear)
                    } else {
                        Picker("쿠폰 상태", selection: $filter) {
                            ForEach(WalletFilter.allCases) { value in Text(value.rawValue).tag(value) }
                        }.pickerStyle(.segmented).listRowBackground(Color.clear)
                    }
                    if filter == .review {
                        Text("일반 바코드일 수도 있어요. 원본을 보고 기프티콘인지 확인해 주세요.")
                            .font(.footnote).foregroundStyle(ClayTheme.mutedInk).listRowBackground(Color.clear)
                    }
                    if visibleGifticons.isEmpty {
                        ContentUnavailableView(searchText.isEmpty ? filter.emptyTitle : "검색 결과가 없어요",
                            systemImage: searchText.isEmpty ? "gift" : "magnifyingglass",
                            description: Text(searchText.isEmpty ? filter.emptyDescription : "브랜드나 상품명을 바꿔 검색해 보세요."))
                            .listRowBackground(Color.clear)
                    }
                    ForEach(visibleGifticons) { gifticon in
                        NavigationLink(value: gifticon) {
                            GifticonRow(gifticon: gifticon, photoLibraryService: photoLibraryService)
                        }
                        .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { deletion = gifticon } label: { Label("삭제", systemImage: "trash") }
                        }
                    }
                }
            }
            .listStyle(.plain).scrollContentBackground(.hidden).background(ClayTheme.canvas)
            .navigationTitle("모아콘").navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Gifticon.self) { gifticon in
                GifticonDetailView(gifticon: gifticon, photoLibraryService: photoLibraryService)
            }
            .searchable(text: $searchText, prompt: "브랜드·상품 검색")
            .tint(ClayTheme.ink)
            .sheet(isPresented: $showImport) {
                NavigationStack {
                    ManualImportView(photoLibraryService: photoLibraryService)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { showImport = false } } }
                }
            }
            .confirmationDialog("이 항목을 보관함에서 삭제할까요?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    guard let item = deletion else { return }
                    do { try PersistenceService(modelContext: modelContext).delete(item) }
                    catch { modelContext.rollback(); errorMessage = "삭제하지 못했어요. 다시 시도해 주세요." }
                    deletion = nil
                }
                Button("취소", role: .cancel) { deletion = nil }
            }
            .alert("확인해 주세요", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }
}

enum WalletFilter: String, CaseIterable, Identifiable {
    case available = "사용 가능", review = "확인 필요", archived = "지난 쿠폰"
    var id: String { rawValue }
    func includes(_ item: Gifticon) -> Bool {
        switch self {
        case .available: !item.needsReview && !item.isUsed && !item.isExpired()
        case .review: item.needsReview
        case .archived: !item.needsReview && (item.isUsed || item.isExpired())
        }
    }
    var emptyTitle: String {
        switch self {
        case .available: "쓸 쿠폰을 모아볼까요?"
        case .review: "확인할 항목이 없어요"
        case .archived: "지난 쿠폰이 없어요"
        }
    }
    var emptyDescription: String {
        switch self {
        case .available: "사진 추가나 자동 찾기로 시작하세요."
        case .review: "확실하지 않은 바코드는 여기에 따로 보관해요."
        case .archived: "사용 완료하거나 만료된 쿠폰을 모아둡니다."
        }
    }
}

private struct ScanProgressBanner: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(viewModel.phaseTitle, systemImage: "sparkle.magnifyingglass")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(viewModel.processedCount), total: Double(max(viewModel.totalCount, 1)))
            Text("화면을 계속 사용할 수 있어요 · \(viewModel.processedCount)/\(viewModel.totalCount)")
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
                Text("더 많은 기프티콘을 자동으로 찾으려면 사진을 추가로 선택해 주세요.")
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
                        .foregroundStyle(gifticon.isExpired() ? .red : .secondary)
                }
            }
            Spacer()
            if gifticon.needsReview {
                ClayPill(title: "확인 필요", color: ClayTheme.butter)
            } else if gifticon.isUsed {
                ClayPill(title: "사용 완료", color: ClayTheme.mint)
            } else if gifticon.isExpired() {
                ClayPill(title: "만료", color: ClayTheme.butter)
            } else if let expiry = gifticon.expiryDate {
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: expiry)).day ?? 0
                if days <= 7 { ClayPill(title: days == 0 ? "오늘까지" : "D-\(days)", color: ClayTheme.butter) }
            }
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
        .accessibilityLabel("\(gifticon.brand) 기프티콘 이미지")
    }
}
