
import SwiftUI
import WebKit
import UIKit

struct SloopyCCTVPlayer: View {
    let cameraID: String

    private var playerURL: URL {
        var components = URLComponents(
            string: "https://algeeeeeeeeee.github.io/Sloopy/"
        )!
        components.path += "index.html"
        components.queryItems = [
            URLQueryItem(name: "camera", value: cameraID)
        ]
        return components.url!
    }

    var body: some View {
        CCTVWebView(url: playerURL)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CCTVWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(
            red: 0.09, green: 0.15, blue: 0.19, alpha: 1
        )

        webView.load(URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData
        ))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.targetFrame == nil,
               let destination = navigationAction.request.url {
                UIApplication.shared.open(destination)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
