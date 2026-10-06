import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var started = false
    private let status = UILabel()
    private let retry = UIButton(type: .system)
    private let close = UIButton(type: .system)
    private var providers: [NSItemProvider] = []
    private var completed = 0
    private var failures: [NSItemProvider] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        status.font = .preferredFont(forTextStyle: .body)
        status.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 0
        status.textAlignment = .center
        retry.setTitle("실패한 사진 재시도", for: .normal)
        retry.addTarget(self, action: #selector(retryFailed), for: .touchUpInside)
        close.setTitle("닫기", for: .normal)
        close.addTarget(self, action: #selector(finish), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [status, retry, close])
        stack.axis = .vertical; stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            retry.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            close.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        providers = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem }.flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) } ?? []
        process(providers)
    }

    private func process(_ queue: [NSItemProvider]) {
        retry.isHidden = true; close.isEnabled = false
        status.text = "사진 저장 중"
        loadNext(queue, index: 0)
    }

    private func loadNext(_ queue: [NSItemProvider], index: Int) {
        guard index < queue.count else {
            close.isEnabled = true
            retry.isHidden = failures.isEmpty
            status.text = queue.isEmpty && completed == 0 ? "공유할 사진이 없습니다." :
                "저장 \(completed)장 · 실패 \(failures.count)장\n모아콘을 열어 쿠폰 정보를 확인해 주세요."
            UIAccessibility.post(notification: .announcement, argument: status.text)
            return
        }
        let provider = queue[index]
        // File representation avoids allocating an unbounded attachment before checking its size.
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, _ in
            var succeeded = false
            if let url {
                do {
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    try SharedImageInbox.validateSize(size)
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    try SharedImageInbox.validateImage(data)
                    _ = try SharedImageInbox.enqueue(imageData: data)
                    succeeded = true
                } catch { }
            }
            let saved = succeeded
            DispatchQueue.main.async {
                guard let self else { return }
                if saved { self.completed += 1 } else { self.failures.append(provider) }
                self.loadNext(queue, index: index + 1)
            }
        }
    }

    @objc private func retryFailed() {
        let queue = failures
        failures = []
        process(queue)
    }
    @objc private func finish() { extensionContext?.completeRequest(returningItems: nil) }
}
