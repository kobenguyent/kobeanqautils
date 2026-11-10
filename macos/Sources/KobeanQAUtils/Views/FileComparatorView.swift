import SwiftUI
import AppKit

enum DiffLineType {
    case same, added, deleted
}

struct DiffEntry: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let leftLineNum: Int?
    let rightLineNum: Int?
    let text: String
}

struct FileComparatorView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var file1Name: String = "Left File (Original)"
    @State private var file2Name: String = "Right File (Modified)"
    @State private var text1: String = ""
    @State private var text2: String = ""
    @State private var viewMode: ComparatorMode = .sideBySide
    @State private var ignoreWhitespace: Bool = false
    @State private var ignoreCase: Bool = false
    @State private var diffEntries: [DiffEntry] = []
    @State private var similarityPercent: Double = 100.0
    @State private var addedCount: Int = 0
    @State private var deletedCount: Int = 0
    
    enum ComparatorMode: String, CaseIterable {
        case sideBySide = "Side-by-Side"
        case unified = "Unified Diff"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .fileComparator, onReset: loadSampleDiff)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Top Controls & Metrics Bar
            HStack(spacing: 14) {
                Button(action: { openFile(isLeft: true) }) {
                    Label("Open File 1", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { openFile(isLeft: false) }) {
                    Label("Open File 2", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: loadSampleDiff) {
                    Label("Load Sample", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Picker("View", selection: $viewMode) {
                    ForEach(ComparatorMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Toggle("Ignore Whitespace", isOn: $ignoreWhitespace)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .onChange(of: ignoreWhitespace) { _ in computeDiff() }
                
                Button(action: exportUnifiedDiff) {
                    Label("Export .diff", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Stats Row
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Similarity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", similarityPercent))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(similarityPercent > 80 ? .green : (similarityPercent > 50 ? .orange : .red))
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("+\(addedCount) additions")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("-\(deletedCount) deletions")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("\(diffEntries.count) total diff lines")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Diff Content Area
            if viewMode == .sideBySide {
                sideBySideDiffView
            } else {
                unifiedDiffView
            }
        }
        .onAppear {
            if text1.isEmpty && text2.isEmpty {
                loadSampleDiff()
            }
        }
    }
    
    // MARK: - Side by Side View
    private var sideBySideDiffView: some View {
        HSplitView {
            // Left Editor / Viewer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(file1Name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                
                TextEditor(text: $text1)
                    .font(.system(.caption, design: .monospaced))
                    .onChange(of: text1) { _ in computeDiff() }
            }
            .frame(minWidth: 250)
            
            // Right Editor / Viewer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(file2Name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                
                TextEditor(text: $text2)
                    .font(.system(.caption, design: .monospaced))
                    .onChange(of: text2) { _ in computeDiff() }
            }
            .frame(minWidth: 250)
        }
    }
    
    // MARK: - Unified Diff View
    private var unifiedDiffView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(diffEntries) { entry in
                    HStack(spacing: 8) {
                        // Left line num
                        Text(entry.leftLineNum.map { "\($0)" } ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                        
                        // Right line num
                        Text(entry.rightLineNum.map { "\($0)" } ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                        
                        // Diff sign
                        Text(prefixSign(entry.type))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(signColor(entry.type))
                            .frame(width: 14)
                        
                        // Line content
                        Text(entry.text)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(rowBackground(entry.type))
                }
            }
        }
    }
    
    // MARK: - Diff Computation
    private func computeDiff() {
        let lines1 = text1.components(separatedBy: .newlines)
        let lines2 = text2.components(separatedBy: .newlines)
        
        var results: [DiffEntry] = []
        var added = 0
        var deleted = 0
        var matches = 0
        
        var i1 = 0
        var i2 = 0
        
        while i1 < lines1.count || i2 < lines2.count {
            if i1 < lines1.count && i2 < lines2.count {
                let l1 = normalize(lines1[i1])
                let l2 = normalize(lines2[i2])
                
                if l1 == l2 {
                    results.append(DiffEntry(type: .same, leftLineNum: i1 + 1, rightLineNum: i2 + 1, text: lines1[i1]))
                    matches += 1
                    i1 += 1
                    i2 += 1
                } else {
                    // Check if line2 exists further in line1
                    if let foundIndex = lines1[i1...].firstIndex(where: { normalize($0) == l2 }) {
                        // Lines before foundIndex in lines1 were deleted
                        while i1 < foundIndex {
                            results.append(DiffEntry(type: .deleted, leftLineNum: i1 + 1, rightLineNum: nil, text: lines1[i1]))
                            deleted += 1
                            i1 += 1
                        }
                    } else {
                        // Added in lines2
                        results.append(DiffEntry(type: .added, leftLineNum: nil, rightLineNum: i2 + 1, text: lines2[i2]))
                        added += 1
                        i2 += 1
                    }
                }
            } else if i1 < lines1.count {
                results.append(DiffEntry(type: .deleted, leftLineNum: i1 + 1, rightLineNum: nil, text: lines1[i1]))
                deleted += 1
                i1 += 1
            } else if i2 < lines2.count {
                results.append(DiffEntry(type: .added, leftLineNum: nil, rightLineNum: i2 + 1, text: lines2[i2]))
                added += 1
                i2 += 1
            }
        }
        
        self.diffEntries = results
        self.addedCount = added
        self.deletedCount = deleted
        
        let total = matches + added + deleted
        if total > 0 {
            self.similarityPercent = (Double(matches) / Double(total)) * 100.0
        } else {
            self.similarityPercent = 100.0
        }
    }
    
    private func normalize(_ str: String) -> String {
        var s = str
        if ignoreWhitespace {
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if ignoreCase {
            s = s.lowercased()
        }
        return s
    }
    
    // MARK: - UI Helpers
    private func prefixSign(_ type: DiffLineType) -> String {
        switch type {
        case .same: return " "
        case .added: return "+"
        case .deleted: return "-"
        }
    }
    
    private func signColor(_ type: DiffLineType) -> Color {
        switch type {
        case .same: return .secondary
        case .added: return .green
        case .deleted: return .red
        }
    }
    
    private func rowBackground(_ type: DiffLineType) -> Color {
        switch type {
        case .same: return Color.clear
        case .added: return Color.green.opacity(0.12)
        case .deleted: return Color.red.opacity(0.12)
        }
    }
    
    // MARK: - File I/O
    private func openFile(isLeft: Bool) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                if isLeft {
                    file1Name = url.lastPathComponent
                    text1 = content
                } else {
                    file2Name = url.lastPathComponent
                    text2 = content
                }
                computeDiff()
            }
        }
    }
    
    private func exportUnifiedDiff() {
        var diff = "--- \(file1Name)\n+++ \(file2Name)\n@@ -1,0 +1,0 @@\n"
        for e in diffEntries {
            diff += "\(prefixSign(e.type)) \(e.text)\n"
        }
        ClipboardHelper.copy(diff)
        appState.showToast("Unified diff copied to clipboard")
    }
    
    private func loadSampleDiff() {
        file1Name = "package.json (v1.0.0)"
        file2Name = "package.json (v1.1.0)"
        
        text1 = """
        {
          "name": "kobeanqautils",
          "version": "1.0.0",
          "description": "QA and developer utilities suite",
          "scripts": {
            "test": "vitest run",
            "build": "vite build"
          },
          "dependencies": {
            "react": "^18.2.0",
            "react-dom": "^18.2.0"
          }
        }
        """
        
        text2 = """
        {
          "name": "kobeanqautils",
          "version": "1.1.0",
          "description": "Native macOS and web QA automation developer suite",
          "scripts": {
            "test": "vitest run",
            "build": "vite build",
            "build:mac": "./scripts/install-native-mac.sh"
          },
          "dependencies": {
            "react": "^18.3.1",
            "react-dom": "^18.3.1",
            "lucide-react": "^0.344.0"
          }
        }
        """
        
        computeDiff()
    }
}
