import SwiftUI
import AppKit

struct NativeLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let tag: String
    let message: String
    let stackTrace: String?
    
    enum LogLevel: String, CaseIterable, Identifiable {
        case error = "ERROR"
        case warn = "WARN"
        case info = "INFO"
        case debug = "DEBUG"
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warn: return .orange
            case .info: return .blue
            case .debug: return .secondary
            }
        }
    }
}

struct LogCollectorView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedLevel: String = "ALL"
    @State private var searchQuery: String = ""
    
    @State private var logs: [NativeLogEntry] = [
        NativeLogEntry(timestamp: Date().addingTimeInterval(-120), level: .info, tag: "AppInit", message: "KobeanQAUtils native app launched on macOS", stackTrace: nil),
        NativeLogEntry(timestamp: Date().addingTimeInterval(-90), level: .info, tag: "BrandEngine", message: "Loaded official AppLogo.png and AppIcon.icns", stackTrace: nil),
        NativeLogEntry(timestamp: Date().addingTimeInterval(-45), level: .warn, tag: "NetworkMonitor", message: "Slow response detected on https://api.example.com (980ms)", stackTrace: nil),
        NativeLogEntry(timestamp: Date().addingTimeInterval(-15), level: .error, tag: "AuthHandler", message: "Token validation failed: expired Bearer token", stackTrace: "AuthService.swift:84 in validateToken()\nAppMain.swift:142 in performHandshake()"),
        NativeLogEntry(timestamp: Date().addingTimeInterval(-5), level: .debug, tag: "CryptoKit", message: "AES-256-GCM sealed box authenticated successfully", stackTrace: nil)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .logCollector)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Toolbar
            HStack(spacing: 12) {
                Picker("Level", selection: $selectedLevel) {
                    Text("ALL").tag("ALL")
                    ForEach(NativeLogEntry.LogLevel.allCases) { l in
                        Text(l.rawValue).tag(l.rawValue)
                    }
                }
                .frame(maxWidth: 140)
                
                TextField("Search logs...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
                
                Button("Simulate Error") {
                    logs.append(NativeLogEntry(
                        timestamp: Date(),
                        level: .error,
                        tag: "TestRunner",
                        message: "Assertion failure: expected status 200 but got 500 Internal Server Error",
                        stackTrace: "PlaywrightEngine.swift:42\nTestRunner.swift:108"
                    ))
                }
                .buttonStyle(.bordered)
                
                Button("Export GitHub Issue") {
                    exportGitHubIssue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            
            // Stats Badges
            HStack(spacing: 12) {
                statPill(label: "Total Logs", count: logs.count, color: .primary)
                statPill(label: "Errors", count: logs.filter { $0.level == .error }.count, color: .red)
                statPill(label: "Warnings", count: logs.filter { $0.level == .warn }.count, color: .orange)
                
                Spacer()
                
                Button("Clear Logs") {
                    logs.removeAll()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 24)
            
            // Log Stream
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredLogs) { entry in
                        logCard(entry)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var filteredLogs: [NativeLogEntry] {
        logs.filter { entry in
            let matchesLevel = selectedLevel == "ALL" || entry.level.rawValue == selectedLevel
            if !matchesLevel { return false }
            if searchQuery.isEmpty { return true }
            let q = searchQuery.lowercased()
            return entry.message.lowercased().contains(q) ||
                   entry.tag.lowercased().contains(q) ||
                   (entry.stackTrace?.lowercased().contains(q) ?? false)
        }
    }
    
    private func logCard(_ entry: NativeLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.level.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.level.color.opacity(0.15))
                    .foregroundColor(entry.level.color)
                    .cornerRadius(4)
                
                Text(entry.tag)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(DateFormatter.localizedString(from: entry.timestamp, dateStyle: .none, timeStyle: .medium))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Text(entry.message)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)
            
            if let stack = entry.stackTrace {
                Text(stack)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.06))
                    .cornerRadius(4)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
    
    private func statPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(6)
    }
    
    private func exportGitHubIssue() {
        let errors = logs.filter { $0.level == .error }
        let body = """
## Bug Report / Diagnostic Logs

### Summary
Captured \(errors.count) error(s) during application execution.

### Error Logs
```
\(errors.map { "[\($0.level.rawValue)] \($0.tag): \($0.message)\($0.stackTrace.map { "\n" + $0 } ?? "")" }.joined(separator: "\n---\n"))
```

### Environment
- OS: macOS (Apple Silicon / Intel)
- App: KobeanQAUtils Native Suite
"""
        ClipboardHelper.copy(body)
        appState.showToast("Copied GitHub Issue markdown to clipboard")
    }
}
