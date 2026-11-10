import Foundation
import Combine
import WebKit

enum AppEnvironment: String, CaseIterable, Identifiable {
    case bundled = "Bundled App"
    case devServer = "Live Dev Server (5173)"
    
    var id: String { rawValue }
    
    var url: URL {
        switch self {
        case .bundled:
            return URL(string: "kobean://app/index.html")!
        case .devServer:
            return URL(string: "http://localhost:5173")!
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var environment: AppEnvironment = .bundled
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var pageTitle: String = "KobeanQAUtils"
    @Published var currentURL: URL?
    @Published var zoomFactor: Double = 1.0
    @Published var isDevServerReachable: Bool = false
    
    weak var webView: WKWebView?
    
    init() {
        checkDevServer()
    }
    
    func checkDevServer() {
        guard let url = URL(string: "http://localhost:5173") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 1.5
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            Task { @MainActor [weak self] in
                if let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) {
                    self?.isDevServerReachable = true
                } else {
                    self?.isDevServerReachable = false
                }
            }
        }.resume()
    }
    
    func loadCurrentEnvironment() {
        webView?.load(URLRequest(url: environment.url))
    }
    
    func toggleEnvironment() {
        environment = (environment == .bundled) ? .devServer : .bundled
        loadCurrentEnvironment()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func goBack() {
        if webView?.canGoBack == true {
            webView?.goBack()
        }
    }
    
    func goForward() {
        if webView?.canGoForward == true {
            webView?.goForward()
        }
    }
    
    func zoomIn() {
        zoomFactor = min(zoomFactor + 0.1, 2.5)
        applyZoom()
    }
    
    func zoomOut() {
        zoomFactor = max(zoomFactor - 0.1, 0.5)
        applyZoom()
    }
    
    func resetZoom() {
        zoomFactor = 1.0
        applyZoom()
    }
    
    private func applyZoom() {
        let script = "document.body.style.zoom = '\(zoomFactor)';"
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
}
