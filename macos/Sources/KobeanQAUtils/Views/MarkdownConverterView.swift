import SwiftUI
import AppKit

struct MarkdownConverterView: View {
    @EnvironmentObject private var appState: AppState
    
    enum ConversionMode: String, CaseIterable, Identifiable {
        case mdToConfluence = "Markdown ➔ Confluence / Jira"
        case confluenceToMd = "Confluence / Jira ➔ Markdown"
        var id: String { rawValue }
    }
    
    @State private var mode: ConversionMode = .mdToConfluence
    @State private var inputSource: String = """
# Sprint 42 QA Test Report
**Author:** Kobean QA Team
**Status:** Completed successfully

## Summary
> Automated regression tests executed across all target platforms with 100% pass rate.

### Test Environment
| Platform | Version | Status |
|---|---|---|
| macOS Sequoia | 15.1 | Passed |
| iOS Simulator | 18.0 | Passed |
| WebApp (Chrome) | 130 | Passed |

### Execution Command
```bash
npm run test:all
./scripts/install-native-mac.sh --launch
```

### Action Items
- Verify new branding assets in release bundle
- Deploy package to testing channel
- Update documentation links: [KobeanQAUtils](https://github.com/kobenguyent/kobeanqautils)
"""
    @State private var convertedOutput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .markdownConverter)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Toolbar
            HStack(spacing: 16) {
                Picker("Direction", selection: $mode) {
                    ForEach(ConversionMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .frame(maxWidth: 300)
                .onChange(of: mode) { _ in
                    convert()
                }
                
                Button("Sample MD") {
                    inputSource = "# Sample Title\n**Bold text**, _italic text_, and `inline code`.\n\n```python\nprint('Hello world!')\n```\n\n- Task item 1\n- Task item 2\n\n> Important QA note"
                    convert()
                }
                .buttonStyle(.link)
                .font(.subheadline)
                
                Spacer()
                
                Button("Clear") {
                    inputSource = ""
                    convertedOutput = ""
                }
                .buttonStyle(.borderless)
                
                Button {
                    ClipboardHelper.copy(convertedOutput)
                    appState.showToast("Copied converted markup")
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(convertedOutput.isEmpty)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane Editors
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Input Column
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mode == .mdToConfluence ? "Markdown Input" : "Confluence Markup Input")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $inputSource)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .onChange(of: inputSource) { _ in
                                convert()
                            }
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Output Column
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mode == .mdToConfluence ? "Confluence / Jira Wiki Markup" : "Markdown Output")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $convertedOutput)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            convert()
        }
    }
    
    // MARK: - Parser & Converter
    private func convert() {
        if mode == .mdToConfluence {
            convertedOutput = markdownToConfluence(inputSource)
        } else {
            convertedOutput = confluenceToMarkdown(inputSource)
        }
    }
    
    private func markdownToConfluence(_ md: String) -> String {
        let lines = md.components(separatedBy: "\n")
        var result: [String] = []
        var inCodeBlock = false
        var codeLang = ""
        var codeLines: [String] = []
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Code Block
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                if inCodeBlock {
                    // Close block
                    result.append(codeLines.joined(separator: "\n"))
                    result.append("{code}")
                    codeLines.removeAll()
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                    codeLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    let header = codeLang.isEmpty ? "{code}" : "{code:language=\(codeLang)}"
                    result.append(header)
                }
                i += 1
                continue
            }
            
            if inCodeBlock {
                codeLines.append(line)
                i += 1
                continue
            }
            
            // Headings
            if line.hasPrefix("###### ") {
                result.append("h6. " + applyInlineMd(String(line.dropFirst(7))))
                i += 1; continue
            } else if line.hasPrefix("##### ") {
                result.append("h5. " + applyInlineMd(String(line.dropFirst(6))))
                i += 1; continue
            } else if line.hasPrefix("#### ") {
                result.append("h4. " + applyInlineMd(String(line.dropFirst(5))))
                i += 1; continue
            } else if line.hasPrefix("### ") {
                result.append("h3. " + applyInlineMd(String(line.dropFirst(4))))
                i += 1; continue
            } else if line.hasPrefix("## ") {
                result.append("h2. " + applyInlineMd(String(line.dropFirst(3))))
                i += 1; continue
            } else if line.hasPrefix("# ") {
                result.append("h1. " + applyInlineMd(String(line.dropFirst(2))))
                i += 1; continue
            }
            
            // Blockquote
            if line.hasPrefix(">") {
                var quotes: [String] = []
                while i < lines.count && lines[i].hasPrefix(">") {
                    let text = lines[i].replacingOccurrences(of: "^>\\s?", with: "", options: .regularExpression)
                    quotes.append(applyInlineMd(text))
                    i += 1
                }
                result.append("{quote}\n" + quotes.joined(separator: "\n") + "\n{quote}")
                continue
            }
            
            // Tables
            if line.hasPrefix("|") && i + 1 < lines.count && lines[i+1].contains("---") {
                // Header row
                let headers = line.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                let confHeader = "|| " + headers.map { applyInlineMd($0.trimmingCharacters(in: .whitespaces)) }.joined(separator: " || ") + " ||"
                result.append(confHeader)
                i += 2 // skip separator row
                
                // Content rows
                while i < lines.count && lines[i].hasPrefix("|") {
                    let cells = lines[i].components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    let confRow = "| " + cells.map { applyInlineMd($0.trimmingCharacters(in: .whitespaces)) }.joined(separator: " | ") + " |"
                    result.append(confRow)
                    i += 1
                }
                continue
            }
            
            // Lists
            if line.range(of: "^\\s*[-*+] ", options: .regularExpression) != nil {
                let convertedList = line.replacingOccurrences(of: "^(\\s*)[-*+] ", with: "$1* ", options: .regularExpression)
                result.append(applyInlineMd(convertedList))
                i += 1; continue
            }
            if line.range(of: "^\\s*\\d+\\. ", options: .regularExpression) != nil {
                let convertedList = line.replacingOccurrences(of: "^(\\s*)\\d+\\. ", with: "$1# ", options: .regularExpression)
                result.append(applyInlineMd(convertedList))
                i += 1; continue
            }
            
            // Standard line
            result.append(applyInlineMd(line))
            i += 1
        }
        
        return result.joined(separator: "\n")
    }
    
    private func applyInlineMd(_ text: String) -> String {
        var res = text
        // Images: ![alt](url) -> !url!
        res = res.replacingOccurrences(of: "!\\[([^\\]]*)\\]\\(([^\\)]+)\\)", with: "!$2!", options: .regularExpression)
        // Links: [label](url) -> [label|url]
        res = res.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", with: "[$1|$2]", options: .regularExpression)
        // Bold: **text** or __text__ -> *text*
        res = res.replacingOccurrences(of: "\\*\\*([^\\*]+)\\*\\*", with: "*$1*", options: .regularExpression)
        res = res.replacingOccurrences(of: "__([^_]+)__", with: "*$1*", options: .regularExpression)
        // Inline code: `code` -> {{code}}
        res = res.replacingOccurrences(of: "`([^`]+)`", with: "{{$1}}", options: .regularExpression)
        // Strikethrough: ~~text~~ -> -text-
        res = res.replacingOccurrences(of: "~~([^~]+)~~", with: "-$1-", options: .regularExpression)
        return res
    }
    
    private func confluenceToMarkdown(_ conf: String) -> String {
        let lines = conf.components(separatedBy: "\n")
        var result: [String] = []
        for line in lines {
            var l = line
            // Headings: h1. -> #
            if l.hasPrefix("h1. ") { l = "# " + String(l.dropFirst(4)) }
            else if l.hasPrefix("h2. ") { l = "## " + String(l.dropFirst(4)) }
            else if l.hasPrefix("h3. ") { l = "### " + String(l.dropFirst(4)) }
            else if l.hasPrefix("h4. ") { l = "#### " + String(l.dropFirst(4)) }
            else if l.hasPrefix("h5. ") { l = "##### " + String(l.dropFirst(4)) }
            else if l.hasPrefix("h6. ") { l = "###### " + String(l.dropFirst(4)) }
            
            // Code blocks
            l = l.replacingOccurrences(of: "\\{code:language=([^\\}]+)\\}", with: "```$1", options: .regularExpression)
            l = l.replacingOccurrences(of: "\\{code\\}", with: "```", options: .regularExpression)
            // Quotes
            l = l.replacingOccurrences(of: "\\{quote\\}", with: "> ", options: .regularExpression)
            // Inline code: {{code}} -> `code`
            l = l.replacingOccurrences(of: "\\{\\{([^\\}]+)\\}\\}", with: "`$1`", options: .regularExpression)
            // Links: [label|url] -> [label](url)
            l = l.replacingOccurrences(of: "\\[([^\\]|]+)\\|([^\\]]+)\\]", with: "[$1]($2)", options: .regularExpression)
            // Bold: *text* -> **text**
            l = l.replacingOccurrences(of: "\\*([^\\*\\s][^\\*]*[^\\*\\s])\\*", with: "**$1**", options: .regularExpression)
            
            result.append(l)
        }
        return result.joined(separator: "\n")
    }
}
