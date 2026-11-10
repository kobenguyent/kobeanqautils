import SwiftUI
import AppKit
import WebKit

struct WebPreviewView: NSViewRepresentable {
    let htmlString: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlString, baseURL: nil)
    }
}

struct HtmlRendererView: View {
    @EnvironmentObject private var appState: AppState
    
    enum ViewportSize: String, CaseIterable, Identifiable {
        case responsive = "Responsive"
        case tablet = "Tablet (768px)"
        case mobile = "Mobile (375px)"
        var id: String { rawValue }
        
        var width: CGFloat? {
            switch self {
            case .responsive: return nil
            case .tablet: return 768
            case .mobile: return 375
            }
        }
    }
    
    @State private var viewport: ViewportSize = .responsive
    @State private var htmlSource: String = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 24px; background: #f8fafc; color: #1e293b; margin: 0; }
    .card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }
    h2 { margin-top: 0; color: #3b82f6; display: flex; align-items: center; gap: 8px; }
    .badge { background: #dbeafe; color: #1d4ed8; font-size: 12px; font-weight: bold; padding: 4px 8px; border-radius: 6px; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid #f1f5f9; }
    th { background: #f8fafc; color: #64748b; font-size: 13px; }
    .btn { display: inline-block; background: #3b82f6; color: white; padding: 8px 16px; border-radius: 8px; text-decoration: none; font-weight: 500; margin-top: 12px; }
  </style>
</head>
<body>
  <div class="card">
    <h2>🍏 KobeanQAUtils Native HTML Sandbox <span class="badge">Live</span></h2>
    <p>Render, inspect, and test rich HTML templates, email newsletters, and QA mockups.</p>
    <table>
      <thead>
        <tr><th>Tool</th><th>Engine</th><th>Status</th></tr>
      </thead>
      <tbody>
        <tr><td>HTML Preview</td><td>Native WebKit</td><td>⚡ Active</td></tr>
        <tr><td>Color Formats</td><td>SwiftUI CoreGraphics</td><td>✅ Passed</td></tr>
        <tr><td>Crypto Engine</td><td>CryptoKit</td><td>🔒 Verified</td></tr>
      </tbody>
    </table>
    <a href="#" class="btn">Explore All Tools</a>
  </div>
</body>
</html>
"""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .htmlRenderer)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Toolbar
            HStack(spacing: 16) {
                Picker("Viewport", selection: $viewport) {
                    ForEach(ViewportSize.allCases) { v in
                        Text(v.rawValue).tag(v)
                    }
                }
                .frame(maxWidth: 220)
                
                Button("Sample Card") {
                    loadCardSample()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button {
                    ClipboardHelper.copy(htmlSource)
                    appState.showToast("Copied HTML source")
                } label: {
                    Label("Copy HTML", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane Editors
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Left: Source Editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HTML / CSS Source")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $htmlSource)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Right: Live Rendering
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sandboxed WebKit Preview")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ZStack {
                            Color(nsColor: .controlBackgroundColor)
                            
                            WebPreviewView(htmlString: htmlSource)
                                .frame(width: viewport.width)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(8)
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func loadCardSample() {
        htmlSource = """
<div style="font-family: sans-serif; padding: 20px; border: 2px dashed #3b82f6; border-radius: 8px;">
  <h3 style="color: #1e3a8a;">Quick QA Test Element</h3>
  <p>Test layout responsiveness and CSS box models.</p>
  <button style="background: #10b981; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">Action Button</button>
</div>
"""
    }
}
