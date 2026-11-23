import Foundation

/// 下载管理：把远程视频下载到缓存目录，支持进度回调与取消
final class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: Double] = [:] // key=本地文件名, value=进度0~1
    @Published var errorMessage: String?

    private var tasks: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        return URLSession(configuration: cfg, delegate: self, delegateQueue: .main)
    }()

    /// 开始下载。
    /// - Parameters:
    ///   - remote: 远程视频 URL
    ///   - local: 本地目标路径（CacheManager.localURL 生成）
    ///   - key: 用于进度追踪的唯一键（一般用 local.lastPathComponent）
    func download(remote: URL, local: URL, key: String) {
        cancel(key: key)
        activeDownloads[key] = 0
        errorMessage = nil
        let task = session.downloadTask(with: remote)
        task.taskDescription = "\(key)||\(local.path)"
        tasks[key] = task
        task.resume()
    }

    func cancel(key: String) {
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
        activeDownloads.removeValue(forKey: key)
    }

    var isDownloading: Bool { !tasks.isEmpty }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let desc = downloadTask.taskDescription else { return }
        let key = desc.components(separatedBy: "||").first ?? ""
        if totalBytesExpectedToWrite > 0 {
            activeDownloads[key] = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let desc = downloadTask.taskDescription else { return }
        let parts = desc.components(separatedBy: "||")
        guard parts.count == 2 else { return }
        let key = parts[0]
        let dest = URL(fileURLWithPath: parts[1])

        do {
            // 下载完成，把临时文件搬到缓存目录
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            activeDownloads[key] = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.activeDownloads.removeValue(forKey: key)
                self.tasks.removeValue(forKey: key)
                CacheManager.shared.refresh()
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            activeDownloads.removeValue(forKey: key)
            tasks.removeValue(forKey: key)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let key = task.taskDescription?.components(separatedBy: "||").first ?? "下载"
            errorMessage = "\(key) 下载失败: \(error.localizedDescription)"
            activeDownloads.removeValue(forKey: key)
            tasks.removeValue(forKey: key)
        }
    }
}
