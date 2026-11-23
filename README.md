# VideoCacheApp — iOS 视频缓存播放器

一个极简 iOS App：输入视频 URL → 自动下载到 App 沙盒缓存目录 → 本地播放 + 缓存管理。
为 **TrollStore（巨魔）** 设计：无签名编译、ldid 伪签，装完即用，不需要开发者账号/越狱。

## 功能

- 输入 mp4/m4v/mov 直链 → 下载到 `Documents/VideoCache/`
- 下载进度显示、取消
- 缓存列表（大小、时间）、点按播放、滑动删除、一键清空
- 开 `UIFileSharingEnabled`：可用 Finder/iTunes 或 Filza 导出缓存文件

## 缓存路径

```
App 沙盒/Documents/VideoCache/
```

- TrollStore 装的设备：用 **Filza** 进 `/var/mobile/Containers/Data/Application/<UUID>/Documents/VideoCache/` 直接看文件
- 或用 Finder（Mac）/ iTunes（PC）的文件共享导出

## 用 GitHub Actions 自动编译 IPA（无需 Mac）

1. 在 GitHub 新建一个**公开仓库**（名随意，如 `VideoCacheApp`）
2. 把本目录所有文件（含隐藏的 `.github/`）上传到仓库根目录
   ```bash
   cd VideoCacheApp
   git init
   git add -A
   git commit -m "init"
   git remote add origin https://github.com/<你的用户名>/VideoCacheApp.git
   git branch -M main
   git push -u origin main
   ```
3. 打开仓库 → **Actions** 页 → 等 `Build VideoCacheApp IPA` 跑完（约3-5分钟）
4. 进入那次运行 → 页面底部 **Artifacts** → 下载 `VideoCacheApp-TrollStore`（zip）
5. 解压得到 `VideoCacheApp.ipa`

> 首次推送会自动触发编译；也可在 Actions 页手动 `Run workflow`。

## 用 TrollStore 安装

1. 手机已装 TrollStore（巨魔）
2. 把 `VideoCacheApp.ipa` 传到手机（AirDrop / 邮件 / 文件 App / 本地服务器）
3. 在「文件」App 里长按 IPA → 共享 → **TrollStore** → Install
4. 桌面出现 VideoCacheApp，打开即用

## 本地编译（可选，需要 Mac + Xcode）

```bash
brew install xcodegen
cd VideoCacheApp
xcodegen generate
open VideoCacheApp.xcodeproj
# 选任意 iOS 模拟器/真机目标，Code Signing 设为 None，编译
```

编译出的 `.app` 可用 TrollStore 或 ldid 伪签后安装。

## 说明

- 部署目标 iOS 15.0+
- 支持 http/https；`Info.plist` 已开 `NSAllowsArbitraryLoads`（允许 http 直链）
- 只缓存 mp4/m4v/mov；m3u8 流媒体不在支持范围（需 HLS 下载器，另说）

## 文件结构

```
VideoCacheApp/
├── .github/workflows/build.yml   GitHub Actions 自动编译
├── project.yml                   xcodegen 配置
├── README.md                     本文
└── VideoCacheApp/
    ├── VideoCacheAppApp.swift    App 入口
    ├── ContentView.swift         主界面 + 播放器
    ├── CacheManager.swift        缓存管理
    ├── DownloadManager.swift     下载管理
    ├── Info.plist
    └── VideoCacheApp.entitlements
```
