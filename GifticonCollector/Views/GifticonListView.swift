import Photos
import SwiftData
import SwiftUI

struct GifticonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gifticon.createdAt, order: .reverse) private var gifticons: [Gifticon]
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @State private var isShowingScan = false

    var body: some View {
        NavigationStack {
            List {
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
                        GifticonRow(gifticon: gifticon)
                    }
                }
            }
            .navigationTitle("내 기프티콘")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingScan = true
                    } label: {
                        Label("스캔", systemImage: "wand.and.stars")
                    }
                }
            }
            .sheet(isPresented: $isShowingScan) {
                ScanView(photoLibraryService: photoLibraryService, modelContext: modelContext)
            }
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: gifticon.isUsed ? "checkmark.circle.fill" : "gift.fill")
                .foregroundStyle(gifticon.isUsed ? .green : .orange)
                .font(.title2)
                .accessibilityHidden(true)
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
                Image(systemName: gifticon.isUsed ? "arrow.uturn.backward" : "checkmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(gifticon.isUsed ? "사용 처리 취소" : "사용 완료 처리")
        }
        .padding(.vertical, 4)
    }
}
