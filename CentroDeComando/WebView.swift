import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []   // alarmes sonoros sem toque prévio

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        if #available(iOS 16.4, *) { wv.isInspectable = true }

        let rc = UIRefreshControl()
        rc.tintColor = .white
        rc.addTarget(context.coordinator, action: #selector(Coordinator.pulled), for: .valueChanged)
        wv.scrollView.refreshControl = rc

        context.coordinator.webView = wv
        context.coordinator.lastToken = reloadToken
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        let c = context.coordinator
        c.parent = self
        if c.lastToken != reloadToken {
            c.lastToken = reloadToken
            wv.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        var lastToken = 0
        weak var webView: WKWebView?

        init(_ parent: WebView) { self.parent = parent }

        @objc func pulled() {
            guard let wv = webView else { return }
            if wv.url != nil { wv.reload() } else { wv.load(URLRequest(url: parent.url)) }
        }

        // MARK: Navegação
        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            wv.scrollView.refreshControl?.endRefreshing()
            DispatchQueue.main.async { self.parent.loadError = nil }
        }

        func webView(_ wv: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            fail(wv, error)
        }

        func webView(_ wv: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            fail(wv, error)
        }

        private func fail(_ wv: WKWebView, _ error: Error) {
            wv.scrollView.refreshControl?.endRefreshing()
            let ns = error as NSError
            if ns.code == NSURLErrorCancelled { return }
            DispatchQueue.main.async { self.parent.loadError = ns.localizedDescription }
        }

        // Aceita o certificado autoassinado do app.py (só para o servidor configurado)
        func webView(_ wv: WKWebView,
                     didReceive challenge: URLAuthenticationChallenge,
                     completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let ps = challenge.protectionSpace
            if ps.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let trust = ps.serverTrust, ps.host == parent.url.host {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }

        // Links externos abrem no Safari
        func webView(_ wv: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated,
               let u = action.request.url,
               let scheme = u.scheme, ["http", "https"].contains(scheme),
               u.host != parent.url.host {
                UIApplication.shared.open(u)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ wv: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let u = action.request.url {
                if u.host == parent.url.host { wv.load(action.request) } else { UIApplication.shared.open(u) }
            }
            return nil
        }

        // MARK: alert / confirm / prompt do JavaScript
        func webView(_ wv: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            present(a, orElse: completionHandler)
        }

        func webView(_ wv: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(false) })
            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            present(a, orElse: { completionHandler(false) })
        }

        func webView(_ wv: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                     defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (String?) -> Void) {
            let a = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            a.addTextField { $0.text = defaultText }
            a.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(nil) })
            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(a.textFields?.first?.text)
            })
            present(a, orElse: { completionHandler(nil) })
        }

        private func present(_ vc: UIViewController, orElse fallback: () -> Void) {
            if let top = UIApplication.topViewController() {
                top.present(vc, animated: true)
            } else {
                fallback()
            }
        }
    }
}

extension UIApplication {
    static func topViewController() -> UIViewController? {
        let scene = shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
