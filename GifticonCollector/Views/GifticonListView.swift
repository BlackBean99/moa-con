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

    let importMessage: String?

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext, importMessage: String? = nil) {
        self.importMessage = importMessage
        self.photoLibraryService = photoLibraryService
        _scanViewModel = StateObject(wrappedValue: ScanViewModel(photoLibraryService: photoLibraryService, modelContext: modelContext))
    }

    @State private var scanTask: Task<Void, Never>?
    @StateObject private var advertising = AdvertisingService()
    @State private var navigationPath: [Gifticon] = []
    @State private var isSearchPresented = false
    @State private var searchText = ""
    @State private var filter = WalletFilter.available
    @State private var showImport = false
    @State private var showPrivacy = false
    @State private var showReminderSettings = false
    @State private var showImportQueue = false
    @State private var pendingImportCount = 0
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
        NavigationStack(path: $navigationPath) {
            List {
                if pendingImportCount > 0 {
                    Button("가져오기 확인 \(pendingImportCount)개", systemImage: "tray") { showImportQueue = true }
                }
                if let importMessage { Text("최근 " + importMessage).font(.subheadline).foregroundStyle(.secondary) }
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
            .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "브랜드·상품 검색")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isAdvertisementEligible && advertising.canShowAds {
                    WalletAdvertisement(configuration: advertising.configuration).id(advertising.revision)
                }
            }
            .task(id: isAdvertisementEligible) {
                if isAdvertisementEligible { await advertising.prepare() }
            }
            .tint(MoaconTheme.accent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("자동 찾기", systemImage: "photo.badge.magnifyingglass", action: startScan)
                            .disabled(scanViewModel.isScanning)
                        Button("알림 설정", systemImage: "bell") { showReminderSettings = true }
                        Button("가져오기 대기", systemImage: "tray") { showImportQueue = true }
                        if let value = Bundle.main.object(forInfoDictionaryKey: "MoaconSupportURL") as? String,
                           let url = URL(string: value), url.scheme == "https" {
                            Link("고객지원", destination: url)
                        }
                        if let email = Bundle.main.object(forInfoDictionaryKey: "MoaconSupportEmail") as? String, !email.isEmpty,
                           let url = URL(string: "mailto:" + email) {
                            Link("문의", destination: url)
                        }
                        if advertising.privacyOptionsRequired {
                            Button("광고 개인정보 설정", systemImage: "slider.horizontal.3") {
                                Task { await advertising.changePrivacyOptions() }
                            }.disabled(advertising.isUpdatingPrivacy)
                        }
                        Button("개인정보 처리", systemImage: "hand.raised") { showPrivacy = true }
                    } label: { Label("더 보기", systemImage: "ellipsis") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImport = true } label: { Label("사진 추가", systemImage: "plus") }
                        .accessibilityIdentifier("wallet.add")
                }
            }
            .task { refreshImportCount() }
            .onChange(of: importMessage) { _, _ in refreshImportCount() }
            .sheet(isPresented: $showImportQueue, onDismiss: refreshImportCount) { ImportQueueView() }
            .sheet(isPresented: $showReminderSettings) { ReminderSettingsView() }
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView(advertising: advertising) }
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

    private var isAdvertisementEligible: Bool {
        AdPlacement.isEligible(hasCoupons: filter == .available && !visibleGifticons.isEmpty,
            isSearchPresented: isSearchPresented || !searchText.isEmpty,
            isBusy: scanViewModel.isScanning || showImport || showPrivacy || showReminderSettings || showImportQueue || deletion != nil || errorMessage != nil,
            isDetail: !navigationPath.isEmpty)
    }

    private func refreshImportCount() {
        pendingImportCount = ((try? SharedImageInbox.failedFiles().count) ?? 0) + ((try? SharedImageInbox.pendingFiles().count) ?? 0)
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
    @ObservedObject var advertising: AdvertisingService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if let value = Bundle.main.object(forInfoDictionaryKey: "MoaconPrivacyPolicyURL") as? String,
                   let url = URL(string: value), url.scheme == "https" {
                    Section { Link("개인정보처리방침", destination: url) }
                }
                if let name = Bundle.main.object(forInfoDictionaryKey: "MoaconOperatorName") as? String, !name.isEmpty {
                    Section("운영자") { Text(name) }
                }
                Section("사진과 쿠폰") {
                    Text("사진과 바코드는 기기에서 분석합니다. 앱이 사진이나 인식 결과를 외부 서버로 보내지 않습니다.")
                    Text("새로 등록한 쿠폰 이미지는 앱 보관함에 복사합니다. 기존 쿠폰 원본도 사진 접근이 가능할 때 복사합니다. 사진 보관함의 원본을 지우거나 사진 접근을 변경해도 복사본은 남습니다.")
                }
                Section("권한") {
                    Text("사진 접근은 자동 찾기를 선택할 때 요청합니다. 사진 접근을 허용하지 않아도 사진 한 장을 직접 선택할 수 있습니다. 알림 권한은 알림 설정을 선택할 때 요청합니다.")
                }
                Section("저장과 삭제") {
                    Text("쿠폰 정보, 온보딩 완료 여부, 알림 설정과 자동 찾기 제외 목록을 기기에 저장합니다. 삭제한 바코드는 자동 찾기에 다시 나타나지 않도록 제외 목록에 남습니다.")
                    Text("쿠폰 삭제 시 다른 쿠폰이 쓰지 않는 복사본도 삭제합니다. 사진 보관함의 원본은 삭제하지 않습니다. 가져오기 실패 사진은 대기 목록에서 다시 입력하거나 삭제할 수 있습니다. 파일 정리에 실패한 복사본은 남을 수 있습니다.")
                    Text("앱 삭제 시 앱의 로컬 데이터도 제거됩니다. 기기 설정에 따라 앱 데이터가 시스템 백업에 포함될 수 있습니다. 앱 자체의 클라우드 동기화는 제공하지 않습니다.")
                }
                Section("광고") {
                    Text("쿠폰 사진·번호·상품 정보는 광고 요청에 포함하지 않습니다.")
                    if advertising.configuration.mode == .disabled {
                        Text("현재 버전의 광고는 꺼져 있습니다.")
                    } else {
                        Text("배너 광고는 Google AdMob에서 제공합니다. 광고 제공과 부정 사용 방지를 위해 IP 주소, 기기 정보, 광고 상호작용과 진단 정보 등이 처리될 수 있습니다. 개인화 광고를 요청하지 않으며 추적 권한을 요청하지 않습니다.")
                        Link("Google 개인정보처리방침", destination: URL(string: "https://policies.google.com/privacy")!)
                    }
                    if advertising.privacyOptionsRequired {
                        Button("광고 개인정보 설정") { Task { await advertising.changePrivacyOptions() } }
                            .disabled(advertising.isUpdatingPrivacy)
                    }
                    if let error = advertising.privacyError {
                        Text(error).foregroundStyle(.secondary)
                        Button("광고 설정 다시 시도") { Task { await advertising.retryConsent() } }
                            .disabled(advertising.isUpdatingPrivacy)
                    }
                }
                Section("기준일") { Text("2026년 10월 6일") }
            }
            .navigationTitle("개인정보 처리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
        }
    }
}
