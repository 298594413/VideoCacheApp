import Foundation

/// 缓存管理：所有视频存到 App 沙盒 Documents/VideoCache/
/// TrollStore 安装的 App 可通过 Filza 直接访问此目录，也支持 iTunes/Finder 文件共享导出
final class CacheManager: ObservableObject {
    static let shared = CacheManager()

    @Published var cachedFiles: [CachedVideo] = []

    /// 缓存目录：~/Documents/VideoCache
    let cacheDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("VideoCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    private init() {
        refresh()
    }

    /// 刷新增量缓存列表（按修改时间倒序）
    func refresh() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            cachedFiles = []
            return
        }
        cachedFiles = files.compactMap { url in
            let ext = url.pathExtension.lowercased()
            guard ["mp4", "m4v", "mov"].contains(ext) else { return nil }
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
            let date = (attrs?[.modificationDate] as? Date) ?? Date()
            return CachedVideo(url: url, name: url.lastPathComponent, size: size, date: date)
        }.sorted { $0.date > $1.date }
    }

    /// 根据 URL 生成本地文件名（保留扩展名，避免重名）
    func localURL(for remoteURL: URL) -> URL {
        var name = remoteURL.lastPathComponent
        if name.isEmpty || !["mp4", "m4v", "mov"].contains((name as NSString).pathExtension.lowercased()) {
            name = "video_\(Int(Date().timeIntervalSince1970)).mp4"
        }
        // 去掉查询参数带来的非法字符
        name = name.components(separatedBy: "?").first ?? name
        return cacheDir.appendingPathComponent(name)
    }

    /// 总缓存大小
    var totalSize: Int64 {
        cachedFiles.reduce(0) { $0 + $1.size }
    }

    /// 删除单个缓存
    func remove(_ video: CachedVideo) {
        try? FileManager.default.removeItem(at: video.url)
        refresh()
    }

    /// 清空所有缓存
    func clearAll() {
        for v in cachedFiles { try? FileManager.default.removeItem(at: v.url) }
        refresh()
    }
}

struct CachedVideo: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let date: Date

    var sizeText: String {
        if size < 1024 * 1024 { return "\(size / 1024) KB" }
        return String(format: "%.1f MB", Double(size) / 1024 / 1024)
    }
}
