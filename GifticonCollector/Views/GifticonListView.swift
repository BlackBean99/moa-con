import Photos
import SwiftData
import SwiftUI
import UserNotifications

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
    @State private var showPrivacy = false
    @State private var deletion: Gifticon?
    @State private var errorMessage: String?
    @State private var offerSettings = false
    @Environment(\.openURL) private var openURL

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
                if filter != .review {
                    let reviewCount = gifticons.filter(\.needsReview).count
                    if reviewCount > 0 {
                        Button { filter = .review } label: {
                            Label("확인 필요 \(reviewCount)개", systemImage: "questionmark.circle")
                        }
                    }
                }
                if scanViewModel.isScanning {
                    ScanProgressBanner(viewModel: scanViewModel)
                    Button("중단") { scanTask?.cancel() }
                }
                if let result = scanViewModel.resultMessage {
                    Label(result, systemImage: "checkmark.circle").font(.subheadline)

                }
                if let error = scanViewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
                if photoLibraryService.authorizationStatus == .limited {
                    LimitedAccessBanner(photoLibraryService: photoLibraryService)

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
                }
                Section {
                    if visibleGifticons.isEmpty {
                        ContentUnavailableView(searchText.isEmpty ? filter.emptyTitle : "검색 결과 없음",
                            systemImage: searchText.isEmpty ? "gift" : "magnifyingglass",
                            description: Text(searchText.isEmpty ? filter.emptyDescription : ""))
                            .listRowBackground(Color.clear)
                    }
                    ForEach(visibleGifticons) { gifticon in
                        NavigationLink(value: gifticon) {
                            GifticonRow(gifticon: gifticon, photoLibraryService: photoLibraryService)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { deletion = gifticon } label: { Label("삭제", systemImage: "trash") }
                        }
                    }
                } header: {
                    Text("\(visibleGifticons.count)개" + (filter == .available ? " · 만료일순" : ""))
                }
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(MoaconTheme.canvas)
            .navigationTitle("모아콘").navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Gifticon.self) { gifticon in
                GifticonDetailView(gifticon: gifticon, photoLibraryService: photoLibraryService)
            }
            .searchable(text: $searchText, prompt: "브랜드·상품 검색")
            .tint(MoaconTheme.accent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("자동 찾기", systemImage: "photo.badge.magnifyingglass", action: startScan)
                            .disabled(scanViewModel.isScanning)
                        Button("알림 설정", systemImage: "bell") {
                            Task {
                                let settings = await UNUserNotificationCenter.current().notificationSettings()
                                if settings.authorizationStatus == .notDetermined {
                                    await NotificationService.requestAuthorization()
                                } else {
                                    openSettings()
                                }
                            }
                        }
                        Button("개인정보 처리", systemImage: "hand.raised") { showPrivacy = true }
                    } label: { Label("더 보기", systemImage: "ellipsis") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImport = true } label: { Label("사진 추가", systemImage: "plus") }
                        .accessibilityIdentifier("wallet.add")
                }
            }
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
            .sheet(isPresented: $showImport) {
                NavigationStack {
                    ManualImportView(photoLibraryService: photoLibraryService)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { showImport = false } } }
                }
            }
            .confirmationDialog("보관함에서 삭제할까요?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    guard let item = deletion else { return }
                    do { try PersistenceService(modelContext: modelContext).delete(item) }
                    catch { modelContext.rollback(); offerSettings = false; errorMessage = "삭제하지 못했어요. 다시 시도해 주세요." }
                    deletion = nil
                }
                Button("취소", role: .cancel) { deletion = nil }
            }
            .alert("작업을 완료하지 못했어요", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                if offerSettings { Button("설정 열기") { openSettings() } }
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func startScan() {
        offerSettings = false
        scanTask = Task {
            if photoLibraryService.authorizationStatus == .notDetermined {
                _ = await photoLibraryService.requestReadWriteAuthorization()
            }
            if [.authorized, .limited].contains(photoLibraryService.authorizationStatus) {
                await scanViewModel.scanAll()
            } else {
                offerSettings = true
                errorMessage = "자동 찾기에 사진 접근이 필요합니다."
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
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
        case .available: "쿠폰 없음"
        case .review: "확인할 항목 없음"
        case .archived: "지난 쿠폰 없음"
        }
    }
    var emptyDescription: String {
        switch self {
        case .available: "+ 버튼으로 사진 추가"
        case .review: ""
        case .archived: ""
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
            Text("\(viewModel.processedCount)/\(viewModel.totalCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
                Text("선택한 사진에서 검색").font(.headline)
                Button("사진 선택 변경") {
                    isPresentingLimitedPicker = true
                }
                .buttonStyle(.bordered)
            }
        }
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
    let gifticon: Gifticon
    let photoLibraryService: PhotoLibraryService

    var body: some View {
        HStack(alignment: .top, spacing: MoaconTheme.Space.medium) {
            GifticonPhotoView(gifticon: gifticon, photoLibraryService: photoLibraryService, size: 56)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MoaconTheme.Space.small) {
                Text(gifticon.brand).font(.headline)
                Text(gifticon.title).font(.subheadline).foregroundStyle(.secondary)
                if gifticon.needsReview {
                    CouponStatus(title: "확인 필요", symbol: "questionmark.circle")
                } else if gifticon.isUsed {
                    CouponStatus(title: "사용 완료", symbol: "checkmark.circle")
                } else if gifticon.isExpired() {
                    CouponStatus(title: "만료", symbol: "calendar.badge.exclamationmark")
                } else if let expiry = gifticon.expiryDate {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: expiry)).day ?? 0
                    if days <= 7 {
                        CouponStatus(title: days == 0 ? "오늘까지" : "D-\(days)")
                    } else {
                        Text(expiry, format: .dateTime.year().month().day()).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, MoaconTheme.Space.small)
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


private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("사진과 쿠폰") {
                    Text("사진과 바코드는 기기에서 분석합니다. 앱이 사진이나 인식 결과를 외부 서버로 보내지 않습니다.")
                    Text("자동 찾기로 등록한 원본은 사진 보관함에서 불러옵니다. 직접 선택하거나 공유한 이미지는 앱 보관함에 복사합니다.")
                }
                Section("권한") {
                    Text("사진 접근은 자동 찾기를 선택할 때 요청합니다. 사진 접근을 허용하지 않아도 사진 한 장을 직접 선택할 수 있습니다. 알림 권한은 알림 설정을 선택할 때 요청합니다.")
                }
                Section("저장과 삭제") {
                    Text("쿠폰 정보, 온보딩 완료 여부와 자동 찾기 제외 목록을 기기에 저장합니다. 삭제한 바코드는 자동 찾기에 다시 나타나지 않도록 제외 목록에 남습니다.")
                    Text("쿠폰 삭제 시 다른 쿠폰이 쓰지 않는 복사본도 삭제합니다. 사진 보관함의 원본은 삭제하지 않습니다. 가져오기 실패 파일이나 파일 정리에 실패한 복사본은 남을 수 있습니다.")
                    Text("앱 삭제 시 앱의 로컬 데이터도 제거됩니다. 기기 설정에 따라 앱 데이터가 시스템 백업에 포함될 수 있습니다. 앱 자체의 클라우드 동기화는 제공하지 않습니다.")
                }
                Section("기준일") { Text("2026년 10월 6일") }
            }
            .navigationTitle("개인정보 처리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
        }
    }
}
