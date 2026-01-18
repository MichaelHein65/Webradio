//
//  ContentView.swift
//  Webradio
//
//  Created by Michael Hein on 17.01.26.
//

import SwiftUI
import WebKit
import UIKit

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
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
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
            guard message.name == "haptics" else {
                return
            }
            let type = (message.body as? [String: Any])?["type"] as? String
            let style: UIImpactFeedbackGenerator.FeedbackStyle = (type == "snap") ? .light : .medium
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.prepare()
                generator.impactOccurred()
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
