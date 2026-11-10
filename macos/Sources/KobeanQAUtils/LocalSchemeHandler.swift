import Foundation
import WebKit
import UniformTypeIdentifiers

final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "kobean"
    static let host = "app"
    
    private let distDirectory: URL?
    
    override init() {
        self.distDirectory = Self.findDistDirectory()
        super.init()
        if let dist = self.distDirectory {
            print("[KobeanQAUtils] Using web assets from: \(dist.path)")
        } else {
            print("[KobeanQAUtils] Warning: dist directory not found!")
        }
    }
    
    static func findDistDirectory() -> URL? {
        let fm = FileManager.default
        
        // 1. Check in Bundle resources (bundled inside .app)
        if let bundleResource = Bundle.main.resourceURL?.appendingPathComponent("dist"),
           fm.fileExists(atPath: bundleResource.path) {
            return bundleResource
        }
        
        // 2. Check relative to bundle executable (e.g. KobeanQAUtils.app/Contents/MacOS/../../Resources/dist)
        if let execURL = Bundle.main.executableURL {
            let candidate = execURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources")
                .appendingPathComponent("dist")
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        // 3. Check current working directory or parent directories (for `swift run` / dev)
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let localCandidates = [
            cwd.appendingPathComponent("dist"),
            cwd.appendingPathComponent("../dist"),
            cwd.deletingLastPathComponent().appendingPathComponent("dist"),
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("dist")
        ]
        
        for candidate in localCandidates {
            let standard = candidate.standardized
            if fm.fileExists(atPath: standard.path) {
                return standard
            }
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "LocalSchemeHandler", code: 400, userInfo: nil))
            return
        }
        
        guard let dist = distDirectory else {
            let html = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>KobeanQAUtils</title>
            <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #0f172a; color: #f8fafc; }
            .box { text-align: center; max-width: 500px; padding: 32px; background: #1e293b; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
            h1 { font-size: 20px; margin-bottom: 12px; }
            p { font-size: 14px; color: #94a3b8; line-height: 1.5; }
            code { background: #334155; padding: 2px 6px; border-radius: 4px; font-size: 12px; color: #38bdf8; }
            </style></head>
            <body><div class="box">
            <h1>Web Assets Not Found</h1>
            <p>Please build the web assets first:</p>
            <p><code>npm run build</code></p>
            <p>Or switch to Live Dev Server via <b>Environment &gt; Live Dev Server</b>.</p>
            </div></body></html>
            """
            let data = html.data(using: .utf8)!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
                "Content-Type": "text/html; charset=utf-8",
                "Content-Length": "\(data.count)",
                "Access-Control-Allow-Origin": "*"
            ])!
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            return
        }
        
        var pathComponent = url.path
        if pathComponent.hasPrefix("/") {
            pathComponent = String(pathComponent.dropFirst())
        }
        if pathComponent.isEmpty {
            pathComponent = "index.html"
        }
        
        var targetFile = dist.appendingPathComponent(pathComponent)
        let fm = FileManager.default
        
        // If file doesn't exist and doesn't have an extension, fallback to index.html for SPA routing
        if !fm.fileExists(atPath: targetFile.path) {
            if targetFile.pathExtension.isEmpty {
                targetFile = dist.appendingPathComponent("index.html")
            } else {
                let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Type": "text/plain",
                    "Access-Control-Allow-Origin": "*"
                ])!
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didFinish()
                return
            }
        }
        
        do {
            let data = try Data(contentsOf: targetFile)
            let mimeType = mimeType(for: targetFile.pathExtension)
            let headers: [String: String] = [
                "Content-Type": mimeType,
                "Content-Length": "\(data.count)",
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "no-cache"
            ]
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing to cancel for local file reads
    }
    
    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs":   return "application/javascript; charset=utf-8"
        case "css":         return "text/css; charset=utf-8"
        case "json":        return "application/json; charset=utf-8"
        case "svg":         return "image/svg+xml"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "webp":        return "image/webp"
        case "ico":         return "image/x-icon"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "wasm":        return "application/wasm"
        case "map":         return "application/json"
        case "pdf":         return "application/pdf"
        default:            return "application/octet-stream"
        }
    }
}
