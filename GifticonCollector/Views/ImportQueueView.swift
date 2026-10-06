import SwiftUI
import SwiftData

struct ImportQueueView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []
    @State private var draft: CouponImportDraft?
    @State private var deletion: URL?
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if files.isEmpty { ContentUnavailableView("대기 항목 없음", systemImage: "tray") }
                ForEach(Array(files.enumerated()), id: \.element.lastPathComponent) { index, file in
                    Section("사진 \(index + 1)") {
                        Text(SharedImageInbox.failureMessage(for: file)).foregroundStyle(.secondary)
                        Button("다시 인식") { retry(file) }.disabled(busy)
                        Button("직접 입력") { edit(file) }.disabled(busy)
                        Button("삭제", role: .destructive) { deletion = file }.disabled(busy)
                    }
                }
                if busy { ProgressView("인식 중") }
            }
            .navigationTitle("가져오기 대기").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
            .task { load() }
            .sheet(item: $draft, onDismiss: load) { CouponImportEditor(source: $0, onSaved: load) }
            .alert("작업을 완료하지 못했어요", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("확인", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
            .confirmationDialog("대기 사진을 삭제할까요?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    if let file = deletion {
                        do { try SharedImageInbox.remove(file); load() }
                        catch { self.error = "사진을 삭제하지 못했어요." }
                    }
                    deletion = nil
                }
            }
        }
        .tint(MoaconTheme.accent)
    }

    private func load() {
        do { files = try SharedImageInbox.failedFiles() + SharedImageInbox.pendingFiles() }
        catch { self.error = "대기 목록을 불러오지 못했어요." }
    }
    private func edit(_ file: URL) {
        do {
            let data = try Data(contentsOf: file, options: .mappedIfSafe)
            try SharedImageInbox.validateImage(data)
            draft = CouponImportDraft(data: data, parsed: nil, sourceFilename: file.lastPathComponent)
        } catch { self.error = "원본을 읽을 수 없어요. 다른 사진으로 다시 등록해 주세요." }
    }
    private func retry(_ file: URL) {
        busy = true
        Task {
            defer { busy = false; load() }
            do {
                try SharedImageInbox.retry(file)
                let result = await SharedImportService(modelContext: context).processPending()
                if let storageError = result.storageError { error = storageError }
            } catch { self.error = "재시도하지 못했어요. 원본은 보존됩니다." }
        }
    }
}
