import Foundation

struct VideoItem {
    let title: String
    let detail: String
    let url: URL
}

final class VideoLibrary {

    static let shared = VideoLibrary()

    static let remotePresets: [(String, String, String)] = [
        ("Big Buck Bunny (short)", "https://www.w3schools.com/html/mov_bbb.mp4", "Streaming · 1 MB"),
        ("For Bigger Blazes", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4", "Streaming · 3 MB"),
        ("For Bigger Escapes", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4", "Streaming · 3 MB"),
        ("For Bigger Fun", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4", "Streaming · 3 MB"),
        ("For Bigger Joyrides", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4", "Streaming · 3 MB")
    ]

    static let videoExtensions = ["mp4", "mov", "m4v"]

    private(set) var items: [VideoItem] = []
    var onChange: (() -> Void)?

    func reload() {
        var list: [VideoItem] = []

        if let bundled = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
            list.append(VideoItem(title: "Sample Video", detail: "Stored on watch", url: bundled))
        }
        for (title, urlString, detail) in Self.remotePresets {
            if let url = URL(string: urlString) {
                list.append(VideoItem(title: title, detail: detail, url: url))
            }
        }
        list.append(contentsOf: Self.downloadedVideos())

        DispatchQueue.main.async {
            self.items = list
            self.onChange?()
        }
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func downloadedVideos() -> [VideoItem] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]) else {
            return []
        }
        let videos = files
            .filter { videoExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        return videos.map { url in
            let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let sizeMB = Double(bytes) / 1_048_576
            return VideoItem(
                title: url.deletingPathExtension().lastPathComponent,
                detail: String(format: "Saved on watch · %.1f MB", sizeMB),
                url: url)
        }
    }

    @discardableResult
    static func store(fileAt src: URL, preferredName: String) -> Bool {
        let fm = FileManager.default
        var name = preferredName
        if !videoExtensions.contains((name as NSString).pathExtension.lowercased()) {
            name += ".mp4"
        }
        let sanitized = name.components(
            separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
        if sanitized.isEmpty { return false }

        var dest = documentsDirectory.appendingPathComponent(sanitized)
        var bump = 1
        while fm.fileExists(atPath: dest.path) {
            dest = documentsDirectory.appendingPathComponent("\(sanitized)-\(bump)")
            bump += 1
        }
        do {
            try fm.moveItem(at: src, to: dest)
            return true
        } catch {
            return false
        }
    }
}

private extension URL {
    var creationDate: Date? {
        (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
    }
}
