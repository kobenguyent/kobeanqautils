import SwiftUI

struct TextAnalyzerView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var text: String = "Quality assurance (QA) in software development ensures that the product meets defined standards of quality, reliability, and performance before release."
    
    private var stats: (chars: Int, charsNoSpaces: Int, words: Int, lines: Int, paragraphs: Int, bytes: Int, readingMinutes: Double) {
        let chars = text.count
        let charsNoSpaces = text.filter { !$0.isWhitespace }.count
        let words = text.split { $0.isWhitespace || $0.isPunctuation }.count
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).count
        let paragraphs = text.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        let bytes = text.data(using: .utf8)?.count ?? 0
        let readingMinutes = Double(words) / 200.0 // 200 wpm
        return (chars, charsNoSpaces, words, lines, paragraphs, bytes, readingMinutes)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolHeaderView(tool: .textAnalyzer) {
                    text = ""
                }
                
                // Stat Cards Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    statCard(title: "Characters", value: "\(stats.chars)")
                    statCard(title: "Without Spaces", value: "\(stats.charsNoSpaces)")
                    statCard(title: "Words", value: "\(stats.words)")
                    statCard(title: "Lines", value: "\(stats.lines)")
                    statCard(title: "Paragraphs", value: "\(stats.paragraphs)")
                    statCard(title: "UTF-8 Bytes", value: "\(stats.bytes)")
                    statCard(title: "Reading Time", value: String(format: "%.1f min", stats.readingMinutes))
                }
                
                // Editor
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Text Content")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let pasted = ClipboardHelper.paste() {
                            Button("Paste") { text = pasted }
                                .buttonStyle(.borderless)
                        }
                    }
                    
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}
