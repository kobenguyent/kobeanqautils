import SwiftUI
import AppKit

struct HeaderCheckResult: Identifiable {
    let id = UUID()
    let headerName: String
    let present: Bool
    let value: String?
    let recommendation: String
    let severity: Severity
    
    enum Severity {
        case high, medium, low, info
    }
}

struct WebsiteScannerView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var targetUrl: String = "https://kobeanqa.com"
    @State private var isScanning: Bool = false
    @State private var statusCode: Int? = nil
    @State private var latencyMs: Int? = nil
    @State private var httpVersion: String? = nil
    @State private var pageTitle: String? = nil
    @State private var metaDescription: String? = nil
    @State private var openGraphTitle: String? = nil
    @State private var responseHeaders: [String: String] = [:]
    @State private var securityChecks: [HeaderCheckResult] = []
    @State private var overallGrade: String = "-"
    @State private var gradeColor: Color = .secondary
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .websiteScanner, onReset: resetScanner)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 18) {
                    // URL Input bar
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                        
                        TextField("Enter URL e.g. https://example.com", text: $targetUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onSubmit {
                                scanTarget()
                            }
                        
                        Button(action: scanTarget) {
                            if isScanning {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 80)
                            } else {
                                Label("Scan Site", systemImage: "bolt.horizontal.fill")
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isScanning || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Results Overview Cards
                    if statusCode != nil {
                        HStack(spacing: 12) {
                            // Grade Card
                            VStack(spacing: 4) {
                                Text("SECURITY GRADE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(overallGrade)
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundColor(gradeColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            
                            // Status Code Card
                            VStack(spacing: 4) {
                                Text("HTTP STATUS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text("\(statusCode ?? 0)")
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(statusCode == 200 ? .green : .orange)
                                Text(statusCode == 200 ? "OK" : "Status Code")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            
                            // Latency Card
                            VStack(spacing: 4) {
                                Text("RESPONSE TIME")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text("\(latencyMs ?? 0) ms")
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor((latencyMs ?? 0) < 400 ? .green : .yellow)
                                Text("Network Latency")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            
                            // SSL / Protocol
                            VStack(spacing: 4) {
                                Text("PROTOCOL & SSL")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Image(systemName: targetUrl.lowercased().hasPrefix("https") ? "lock.shield.fill" : "lock.slash.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(targetUrl.lowercased().hasPrefix("https") ? .green : .red)
                                Text(targetUrl.lowercased().hasPrefix("https") ? "HTTPS (TLS)" : "Insecure HTTP")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        
                        // SEO / Meta Information
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("HTML & Meta Tags", systemImage: "doc.plaintext")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top) {
                                    Text("Title Tag:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(width: 120, alignment: .leading)
                                    Text(pageTitle ?? "(Not found)")
                                        .font(.caption)
                                        .foregroundColor(pageTitle != nil ? .primary : .secondary)
                                        .textSelection(.enabled)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("Meta Description:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(width: 120, alignment: .leading)
                                    Text(metaDescription ?? "(Not found)")
                                        .font(.caption)
                                        .foregroundColor(metaDescription != nil ? .primary : .secondary)
                                        .textSelection(.enabled)
                                }
                                
                                if let og = openGraphTitle {
                                    HStack(alignment: .top) {
                                        Text("OpenGraph Title:")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .frame(width: 120, alignment: .leading)
                                        Text(og)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        
                        // Security Headers Table
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("HTTP Security Headers Audit", systemImage: "shield.lefthalf.filled")
                                    .font(.headline)
                                Spacer()
                                
                                Button(action: exportMarkdownReport) {
                                    Label("Export Report", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(securityChecks) { check in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: check.present ? "checkmark.seal.fill" : "xmark.seal.fill")
                                            .font(.title3)
                                            .foregroundColor(check.present ? .green : (check.severity == .high ? .red : .orange))
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(check.headerName)
                                                    .font(.system(.subheadline, design: .monospaced))
                                                    .fontWeight(.semibold)
                                                
                                                if check.present {
                                                    Text("Present")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.green.opacity(0.15))
                                                        .foregroundColor(.green)
                                                        .cornerRadius(4)
                                                } else {
                                                    Text("Missing")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red.opacity(0.15))
                                                        .foregroundColor(.red)
                                                        .cornerRadius(4)
                                                }
                                            }
                                            
                                            if let val = check.value {
                                                Text(val)
                                                    .font(.system(.caption2, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                                    .textSelection(.enabled)
                                            } else {
                                                Text(check.recommendation)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Scan Logic
    private func scanTarget() {
        var urlStr = targetUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStr.lowercased().hasPrefix("http://") && !urlStr.lowercased().hasPrefix("https://") {
            urlStr = "https://" + urlStr
            targetUrl = urlStr
        }
        
        guard let url = URL(string: urlStr) else {
            errorMessage = "Invalid URL syntax"
            return
        }
        
        isScanning = true
        errorMessage = nil
        
        let start = Date()
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) KobeanQAUtils/2.0 NativeScanner", forHTTPHeaderField: "User-Agent")
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                
                await MainActor.run {
                    self.latencyMs = elapsed
                    if let http = response as? HTTPURLResponse {
                        self.statusCode = http.statusCode
                        var headersDict: [String: String] = [:]
                        for (k, v) in http.allHeaderFields {
                            if let kStr = k as? String, let vStr = v as? String {
                                headersDict[kStr.lowercased()] = vStr
                            }
                        }
                        self.responseHeaders = headersDict
                        
                        // Parse HTML for Title & Meta
                        if let html = String(data: data, encoding: .utf8) {
                            self.pageTitle = extractRegex(html, pattern: "<title[^>]*>(.*?)</title>")
                            self.metaDescription = extractRegex(html, pattern: "<meta[^>]+name=[\"']description[\"'][^>]+content=[\"'](.*?)[\"']")
                            self.openGraphTitle = extractRegex(html, pattern: "<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"'](.*?)[\"']")
                        }
                        
                        // Run Security Header Checks
                        evaluateSecurityHeaders(headersDict)
                    }
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to scan site: \(error.localizedDescription)"
                    self.isScanning = false
                }
            }
        }
    }
    
    private func extractRegex(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let nsString = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)), match.numberOfRanges > 1 else { return nil }
        let r = match.range(at: 1)
        return nsString.substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func evaluateSecurityHeaders(_ headers: [String: String]) {
        let checks: [(name: String, key: String, rec: String, sev: HeaderCheckResult.Severity)] = [
            ("Strict-Transport-Security (HSTS)", "strict-transport-security", "Enforce HTTPS to prevent SSL stripping: 'max-age=31536000; includeSubDomains'", .high),
            ("Content-Security-Policy (CSP)", "content-security-policy", "Mitigate XSS and data injection attacks by restricting authorized sources.", .high),
            ("X-Frame-Options", "x-frame-options", "Prevent clickjacking by disallowing embedding in iframes: 'DENY' or 'SAMEORIGIN'", .high),
            ("X-Content-Type-Options", "x-content-type-options", "Prevent MIME-type sniffing vulnerabilities: 'nosniff'", .medium),
            ("Referrer-Policy", "referrer-policy", "Protect user privacy by controlling referrer headers: 'strict-origin-when-cross-origin'", .medium),
            ("Permissions-Policy", "permissions-policy", "Restrict browser features like camera, microphone, and geolocation.", .low)
        ]
        
        var results: [HeaderCheckResult] = []
        var score = 100
        
        for item in checks {
            if let val = headers[item.key] {
                results.append(HeaderCheckResult(
                    headerName: item.name,
                    present: true,
                    value: val,
                    recommendation: "",
                    severity: item.sev
                ))
            } else {
                results.append(HeaderCheckResult(
                    headerName: item.name,
                    present: false,
                    value: nil,
                    recommendation: item.rec,
                    severity: item.sev
                ))
                switch item.sev {
                case .high: score -= 18
                case .medium: score -= 10
                case .low: score -= 5
                case .info: break
                }
            }
        }
        
        self.securityChecks = results
        
        if score >= 90 {
            overallGrade = "A+"
            gradeColor = .green
        } else if score >= 80 {
            overallGrade = "A"
            gradeColor = .green
        } else if score >= 65 {
            overallGrade = "B"
            gradeColor = .blue
        } else if score >= 50 {
            overallGrade = "C"
            gradeColor = .orange
        } else {
            overallGrade = "F"
            gradeColor = .red
        }
    }
    
    private func exportMarkdownReport() {
        var report = """
        # Website Health & Security Scan Report
        - **Target URL**: \(targetUrl)
        - **HTTP Status**: \(statusCode ?? 0)
        - **Response Latency**: \(latencyMs ?? 0) ms
        - **Overall Grade**: \(overallGrade)
        - **Date**: \(Date().description)
        
        ## Metadata
        - **Title**: \(pageTitle ?? "N/A")
        - **Meta Description**: \(metaDescription ?? "N/A")
        
        ## Security Headers Audit
        | Header | Status | Value / Recommendation |
        |---|---|---|
        """
        for c in securityChecks {
            let status = c.present ? "✅ Present" : "❌ Missing"
            let detail = c.present ? (c.value ?? "") : c.recommendation
            report += "\n| \(c.headerName) | \(status) | \(detail) |"
        }
        
        ClipboardHelper.copy(report)
        appState.showToast("Markdown report copied to clipboard")
    }
    
    private func resetScanner() {
        targetUrl = "https://kobeanqa.com"
        statusCode = nil
        latencyMs = nil
        pageTitle = nil
        metaDescription = nil
        securityChecks = []
        overallGrade = "-"
        errorMessage = nil
    }
}
