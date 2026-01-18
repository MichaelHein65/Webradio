//
//  ContentView.swift
//  Webradio
//
//  Created by Michael Hein on 17.01.26.
//

import SwiftUI
import WebKit
import UIKit
import MediaPlayer

struct ContentView: View {
    @State private var loadStatus = "Loading..."

    var body: some View {
        ZStack(alignment: .topLeading) {
            WebView(statusText: $loadStatus)
                .ignoresSafeArea()

            if loadStatus != "Loaded" {
                Text(loadStatus)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    @Binding var statusText: String

    func makeCoordinator() -> Coordinator {
        Coordinator(statusText: $statusText)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "haptics")
        contentController.add(context.coordinator, name: "nowPlaying")
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebContent") {
            DispatchQueue.main.async {
                statusText = "Loading file: \(url.lastPathComponent)"
            }
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            DispatchQueue.main.async {
                statusText = "index.html not found in bundle"
            }
            let html = """
            <html><body style="font-family: -apple-system; padding: 20px;">
            <h2>index.html not found</h2>
            <p>The WebContent folder was not bundled.</p>
            </body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op: content is static.
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private var statusText: Binding<String>

        init(statusText: Binding<String>) {
            self.statusText = statusText
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "haptics":
                let type = (message.body as? [String: Any])?["type"] as? String
                let style: UIImpactFeedbackGenerator.FeedbackStyle = (type == "snap") ? .light : .medium
                DispatchQueue.main.async {
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.prepare()
                    generator.impactOccurred()
                }
            case "nowPlaying":
                let payload = message.body as? [String: Any]
                let shouldClear = payload?["clear"] as? Bool ?? false
                if shouldClear {
                    NowPlayingInfoManager.shared.clear()
                    return
                }
                let name = payload?["name"] as? String ?? "Webradio"
                let logo = payload?["logo"] as? String
                let logoPath = payload?["logoPath"] as? String
                let logoData = payload?["logoData"] as? String
                NowPlayingInfoManager.shared.update(title: name, logoURLString: logo, logoPath: logoPath, logoDataURLString: logoData)
            default:
                break
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            statusText.wrappedValue = "Loaded"
            print("WKWebView finished loading.")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            statusText.wrappedValue = "Load failed: \(error.localizedDescription)"
            print("WKWebView failed: \(error)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            statusText.wrappedValue = "Load failed: \(error.localizedDescription)"
            print("WKWebView provisional failed: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

final class NowPlayingInfoManager {
    static let shared = NowPlayingInfoManager()

    private let infoCenter = MPNowPlayingInfoCenter.default()
    private var artworkTask: URLSessionDataTask?
    private let artworkSize = CGSize(width: 512, height: 512)
    private lazy var appIconArtwork: MPMediaItemArtwork? = {
        guard let image = fallbackImage() else {
            return nil
        }
        let artworkImage = normalizedArtwork(from: image)
        return MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
    }()

    func update(title: String, logoURLString: String?, logoPath: String?, logoDataURLString: String?) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyAlbumTitle: "Webradio",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0
        ]
        info[MPMediaItemPropertyArtwork] = appIconArtwork

        DispatchQueue.main.async {
            self.infoCenter.nowPlayingInfo = info
            self.infoCenter.playbackState = .playing
        }

        if let logoDataURLString,
           let image = imageFromDataURL(logoDataURLString) {
            let artworkImage = normalizedArtwork(from: image)
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            info[MPMediaItemPropertyArtwork] = artwork
            DispatchQueue.main.async {
                self.infoCenter.nowPlayingInfo = info
                self.infoCenter.playbackState = .playing
            }
            return
        }

        if let logoPath,
           let bundleURL = bundleLogoURL(for: logoPath) {
            artworkTask?.cancel()
            loadArtwork(from: bundleURL, info: info)
            return
        }

        guard let logoURLString,
              let url = URL(string: logoURLString) else {
            return
        }

        artworkTask?.cancel()

        if url.isFileURL {
            loadArtwork(from: url, info: info)
            return
        }

        artworkTask = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let image = UIImage(data: data)
            else {
                info[MPMediaItemPropertyArtwork] = self.appIconArtwork
                DispatchQueue.main.async {
                    self.infoCenter.nowPlayingInfo = info
                    self.infoCenter.playbackState = .playing
                }
                return
            }
            let artworkImage = self.normalizedArtwork(from: image)
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            info[MPMediaItemPropertyArtwork] = artwork
            DispatchQueue.main.async {
                self.infoCenter.nowPlayingInfo = info
                self.infoCenter.playbackState = .playing
            }
        }
        artworkTask?.resume()
    }

    func clear() {
        artworkTask?.cancel()
        infoCenter.nowPlayingInfo = nil
        infoCenter.playbackState = .stopped
    }

    private func appIconImage() -> UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primary["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.last
        else {
            return nil
        }
        return UIImage(named: iconName)
    }

    private func fallbackImage() -> UIImage? {
        if let appIcon = appIconImage() {
            return appIcon
        }
        return radioSymbolImage()
    }

    private func imageFromDataURL(_ dataURLString: String) -> UIImage? {
        let parts = dataURLString.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return nil
        }
        let dataPart = String(parts[1])
        guard let data = Data(base64Encoded: dataPart),
              let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }

    private func bundleLogoURL(for path: String) -> URL? {
        guard !path.isEmpty else {
            return nil
        }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fileManager = FileManager.default
        if let resourceURL = Bundle.main.resourceURL {
            let directURL = resourceURL.appendingPathComponent("WebContent").appendingPathComponent(normalized)
            if fileManager.fileExists(atPath: directURL.path) {
                return directURL
            }
            let logosURL = resourceURL.appendingPathComponent("WebContent/logos").appendingPathComponent((normalized as NSString).lastPathComponent)
            if fileManager.fileExists(atPath: logosURL.path) {
                return logosURL
            }
        }
        let fileName = (normalized as NSString).lastPathComponent
        let baseName = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "WebContent/logos")
    }

    private func loadArtwork(from url: URL, info: [String: Any]) {
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else {
                var infoWithFallback = info
                infoWithFallback[MPMediaItemPropertyArtwork] = self.appIconArtwork
                DispatchQueue.main.async {
                    self.infoCenter.nowPlayingInfo = infoWithFallback
                    self.infoCenter.playbackState = .playing
                }
                return
            }
            var updatedInfo = info
            let artworkImage = self.normalizedArtwork(from: image)
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            updatedInfo[MPMediaItemPropertyArtwork] = artwork
            DispatchQueue.main.async {
                self.infoCenter.nowPlayingInfo = updatedInfo
                self.infoCenter.playbackState = .playing
            }
        }
    }

    private func normalizedArtwork(from image: UIImage) -> UIImage {
        let size = artworkSize
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let inset: CGFloat = 48
            let target = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let scale = min(target.width / image.size.width, target.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (size.width - drawSize.width) / 2,
                y: (size.height - drawSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    private func radioSymbolImage() -> UIImage? {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.black.setFill()
            context.fill(rect)

            let config = UIImage.SymbolConfiguration(pointSize: 240, weight: .semibold)
            let symbol = UIImage(systemName: "radio.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            let symbolSize = symbol?.size ?? .zero
            let origin = CGPoint(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2
            )
            symbol?.draw(in: CGRect(origin: origin, size: symbolSize))
        }
        return image
    }
}
