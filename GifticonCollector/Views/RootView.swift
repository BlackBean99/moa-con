import Photos
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var photoLibraryService = PhotoLibraryService()

    var body: some View {
        GifticonListView(photoLibraryService: photoLibraryService, modelContext: modelContext)
            .task { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
    }

    private func refresh() async {
        photoLibraryService.refreshAuthorizationStatus()
        await SharedImportService(modelContext: modelContext).processPending()
    }
}
