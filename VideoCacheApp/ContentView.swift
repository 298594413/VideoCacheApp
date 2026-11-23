import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var cache = CacheManager.shared
    @StateObject private var downloader = DownloadManager.shared
    @State private var urlText = ""
    @State private var playingVideo: CachedVideo?
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // ---- URL 输入区 ----
                VStack(alignment: .leading, spacing: 8) {
                    Text("视频地址 (mp4 / m4v / mov)")
                        .font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        TextField("https://example.com/video.mp4", text: $urlText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        Button("下载") { startDownload() }
                            .buttonStyle(.borderedProminent)
                            .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty || downloader.isDownloading)
                    }
                    if downloader.isDownloading {
                        ForEach(Array(downloader.activeDownloads.keys), id: \.self) { key in
                            VStack(alignment: .leading) {
                                Text("下载中: \(key) \(Int((downloader.activeDownloads[key] ?? 0) * 100))%")
                                    .font(.caption)
                                ProgressView(value: downloader.activeDownloads[key] ?? 0)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // ---- 缓存列表 ----
                HStack {
                    Text("已缓存 (\(cache.cachedFiles.count))")
                        .font(.headline)
                    Spacer()
                    Text("共 \(cache.cachedFiles.sizeText)")
                        .font(.caption).foregroundColor(.secondary)
                    if !cache.cachedFiles.isEmpty {
                        Button("清空") { cache.clearAll() }
                            .font(.caption)
                    }
                }
                .padding(.horizontal)

                List {
                    ForEach(cache.cachedFiles) { video in
                        HStack {
                            Image(systemName: "film")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(video.name).font(.subheadline).lineLimit(1)
                                Text("\(video.sizeText) · \(video.date, formatter: dateFmt)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button { playingVideo = video } label: {
                                Image(systemName: "play.circle.fill").font(.title2)
                            }.buttonStyle(.plain)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { cache.remove(cache.cachedFiles[i]) }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("VideoCache")
            .sheet(item: $playingVideo) { video in
                PlayerView(video: video)
            }
            .alert("提示", isPresented: $showAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text(downloader.errorMessage ?? "")
            }
            .onChange(of: downloader.errorMessage) { newValue in
                if newValue != nil { showAlert = true }
            }
            .onAppear { cache.refresh() }
        }
    }

    private func startDownload() {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)),
              url.scheme != nil else {
            downloader.errorMessage = "地址无效"
            return
        }
        let local = cache.localURL(for: url)
        let key = local.lastPathComponent
        downloader.download(remote: url, local: local, key: key)
        urlText = ""
    }

    private var dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}

/// 播放本地缓存视频
struct PlayerView: UIViewControllerRepresentable {
    let video: CachedVideo

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: video.url)
        vc.player?.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

extension Array where Element == CachedVideo {
    var sizeText: String {
        let total = reduce(Int64(0)) { $0 + $1.size }
        if total < 1024 * 1024 { return "\(total / 1024) KB" }
        return String(format: "%.1f MB", Double(total) / 1024 / 1024)
    }
}
