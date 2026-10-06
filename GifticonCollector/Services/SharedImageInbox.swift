import Foundation
import ImageIO

enum SharedImageInbox {
    static let appGroup = "group.com.yourteam.gifticoncollector"
    static let maximumBytes = 20 * 1024 * 1024
    private static let folder = "MessageAttachments"

    static var directoryURL: URL? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return FileManager.default.temporaryDirectory.appendingPathComponent("MoaconUITestInbox", isDirectory: true)
        }
        #endif
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent(folder, isDirectory: true)
    }

    static func prepareDirectory() throws {
        guard let directoryURL else { throw InboxError.unavailable }
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    static func validateSize(_ count: Int) throws {
        guard count > 0, count <= maximumBytes else { throw InboxError.tooLarge }
    }

    static func validateImage(_ data: Data) throws {
        try validateSize(data.count)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, Double(width) * Double(height) <= 40_000_000 else { throw InboxError.invalidImage }
    }

    static func enqueue(imageData: Data) throws -> String {
        try validateSize(imageData.count)
        try prepareDirectory()
        let filename = "\(UUID().uuidString).jpg"
        guard let url = directoryURL?.appendingPathComponent(filename) else { throw InboxError.unavailable }
        try imageData.write(to: url, options: .atomic)
        return filename
    }

    static func files(in subfolder: String? = nil) throws -> [URL] {
        try prepareDirectory()
        let root = subfolder.map { directoryURL!.appendingPathComponent($0, isDirectory: true) } ?? directoryURL!
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "jpg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    static func pendingFiles() throws -> [URL] { try files() }
    static func failedFiles() throws -> [URL] { try files(in: "Failed") }

    // Recover the crash window between archiving a file and committing its DB reference.
    static func recoverUnreferencedArchives(referenced: Set<String>) throws -> Int {
        var count = 0
        for file in try files(in: "Saved") where !referenced.contains(file.lastPathComponent) {
            try markFailed(file, message: "보관을 완료하지 못한 사진입니다. 재시도하거나 직접 입력해 주세요.")
            count += 1
        }
        return count
    }

    static func remove(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: url.appendingPathExtension("json"))
    }

    private static func move(_ url: URL, to folder: String?) throws -> URL {
        guard let directoryURL else { throw InboxError.unavailable }
        let root = folder.map { directoryURL.appendingPathComponent($0, isDirectory: true) } ?? directoryURL
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appendingPathComponent(url.lastPathComponent)
        if url != destination {
            guard !FileManager.default.fileExists(atPath: destination.path) else { throw InboxError.destinationExists }
            try FileManager.default.moveItem(at: url, to: destination)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("json"))
        }
        return destination
    }

    static func archive(_ url: URL) throws { _ = try move(url, to: "Saved") }
    static func markFailed(_ url: URL, message: String) throws {
        let destination = try move(url, to: "Failed")
        try JSONEncoder().encode(message).write(to: destination.appendingPathExtension("json"), options: .atomic)
    }
    static func failureMessage(for url: URL) -> String {
        guard let data = try? Data(contentsOf: url.appendingPathExtension("json")),
              let value = try? JSONDecoder().decode(String.self, from: data) else { return "정보 확인이 필요합니다." }
        return value
    }
    static func retry(_ url: URL) throws { _ = try move(url, to: nil) }

    static func url(for filename: String) -> URL? {
        guard !filename.isEmpty, filename == URL(fileURLWithPath: filename).lastPathComponent, let directoryURL else { return nil }
        for folder in ["Saved", "Failed", ""] {
            let root = folder.isEmpty ? directoryURL : directoryURL.appendingPathComponent(folder)
            let url = root.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    enum InboxError: LocalizedError {
        case unavailable, tooLarge, invalidImage, destinationExists
        var errorDescription: String? {
            switch self {
            case .unavailable: "공유 이미지 저장소를 사용할 수 없습니다."
            case .tooLarge: "20MB 이하의 사진을 선택해 주세요."
            case .invalidImage: "사진을 읽을 수 없습니다. 다른 사진을 선택해 주세요."
            case .destinationExists: "같은 이름의 원본이 이미 보관되어 있습니다."
            }
        }
    }
}
