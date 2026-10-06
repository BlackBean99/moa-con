import Foundation

enum SharedImageInbox {
    static let appGroup = "group.com.yourteam.gifticoncollector"
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

    static func enqueue(imageData: Data) throws -> String {
        try prepareDirectory()
        let filename = "\(UUID().uuidString).jpg"
        guard let url = directoryURL?.appendingPathComponent(filename) else { throw InboxError.unavailable }
        try imageData.write(to: url, options: .atomic)
        return filename
    }

    static func pendingFiles() throws -> [URL] {
        try prepareDirectory()
        return try FileManager.default.contentsOfDirectory(at: directoryURL!, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "jpg" }
    }

    static func remove(_ url: URL) throws { try FileManager.default.removeItem(at: url) }
    static func archive(_ url: URL) throws {
        guard let directoryURL else { throw InboxError.unavailable }
        let archive = directoryURL.appendingPathComponent("Saved", isDirectory: true)
        try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
        let destination = archive.appendingPathComponent(url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.moveItem(at: url, to: destination)
        }
    }

    static func url(for filename: String) -> URL? {
        guard filename == URL(fileURLWithPath: filename).lastPathComponent, let directoryURL else { return nil }
        let archived = directoryURL.appendingPathComponent("Saved").appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: archived.path) ? archived : directoryURL.appendingPathComponent(filename)
    }

    enum InboxError: LocalizedError {
        case unavailable
        var errorDescription: String? { "공유 이미지 저장소를 사용할 수 없습니다." }
    }
}
