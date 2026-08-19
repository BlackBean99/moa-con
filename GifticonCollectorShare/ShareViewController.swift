import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleItems()
    }

    private func handleItems() {
        let providers = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []
        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
        guard !imageProviders.isEmpty else { finish(); return }
        let group = DispatchGroup()
        for provider in imageProviders {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                defer { group.leave() }
                guard let data else { return }
                try? SharedImageInbox.enqueue(imageData: data)
            }
        }
        group.notify(queue: .main) { self.finish() }
    }

    private func finish() { extensionContext?.completeRequest(returningItems: nil) }
}
