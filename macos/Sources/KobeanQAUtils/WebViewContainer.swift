import SwiftUI
import WebKit

struct WebViewContainer: NSViewRepresentable {
    @ObservedObject var appState: AppState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let schemeHandler = LocalSchemeHandler()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: LocalSchemeHandler.scheme)
        
        // Enable local storage and developer tools
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        
        context.coordinator.setupObservers(for: webView)
        appState.webView = webView
        
        // Initial load
        let initialURL = appState.environment.url
        webView.load(URLRequest(url: initialURL))
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // State updates handled via AppState observers
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let appState: AppState
        private var observations: [NSKeyValueObservation] = []
        
        init(appState: AppState) {
            self.appState = appState
            super.init()
        }
        
        func setupObservers(for webView: WKWebView) {
            observations = [
                webView.observe(\.canGoBack, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        self?.appState.canGoBack = wv.canGoBack
                    }
                },
                webView.observe(\.canGoForward, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        self?.appState.canGoForward = wv.canGoForward
                    }
                },
                webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        self?.appState.isLoading = wv.isLoading
                    }
                },
                webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        self?.appState.estimatedProgress = wv.estimatedProgress
                    }
                },
                webView.observe(\.title, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        if let title = wv.title, !title.isEmpty {
                            self?.appState.pageTitle = "\(title) — KobeanQAUtils"
                        }
                    }
                },
                webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor [weak self] in
                        self?.appState.currentURL = wv.url
                    }
                }
            ]
        }
        
        // Open external links (github, docs) in system browser
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let isKobeanScheme = url.scheme == LocalSchemeHandler.scheme
            let isLocalhost = url.host == "localhost" || url.host == "127.0.0.1"
            
            if navigationAction.navigationType == .linkActivated {
                if !isKobeanScheme && !isLocalhost {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            return nil
        }
    }
}
