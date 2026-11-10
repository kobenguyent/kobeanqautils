import SwiftUI

struct LoremIpsumView: View {
    @EnvironmentObject private var appState: AppState
    
    enum LoremUnit: String, CaseIterable, Identifiable {
        case paragraphs = "Paragraphs"
        case sentences = "Sentences"
        case words = "Words"
        case bullets = "Bullet List"
        var id: String { rawValue }
    }
    
    enum HtmlWrapper: String, CaseIterable, Identifiable {
        case none = "Plain Text"
        case pTag = "<p> Tag"
        case liTag = "<li> Tag"
        var id: String { rawValue }
    }
    
    @State private var unit: LoremUnit = .paragraphs
    @State private var count: Int = 3
    @State private var startWithLorem: Bool = true
    @State private var wrapper: HtmlWrapper = .none
    @State private var generatedText: String = ""
    
    private let latinWords = [
        "lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", "sed", "do",
        "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore", "magna", "aliqua", "enim",
        "ad", "minim", "veniam", "quis", "nostrud", "exercitation", "ullamco", "laboris", "nisi",
        "aliquip", "ex", "ea", "commodo", "consequat", "duis", "aute", "irure", "in", "reprehenderit",
        "voluptate", "velit", "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint",
        "occaecat", "cupidatat", "non", "proident", "sunt", "culpa", "qui", "officia", "deserunt",
        "mollit", "anim", "id", "est", "laborum", "perspiciatis", "unde", "omnis", "iste", "natus",
        "error", "sit", "voluptatem", "accusantium", "doloremque", "laudantium", "totam", "rem",
        "aperiam", "eaque", "ipsa", "quae", "ab", "illo", "inventore", "veritatis", "quasi", "architecto",
        "beatae", "vitae", "dicta", "sunt", "explicabo", "nemo", "enim", "ipsam", "voluptatem"
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .loremIpsum)
                
                // Controls Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        Picker("Type", selection: $unit) {
                            ForEach(LoremUnit.allCases) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .frame(maxWidth: 220)
                        
                        HStack(spacing: 8) {
                            Text("Count:")
                                .font(.subheadline)
                            Stepper("\(count)", value: $count, in: 1...50)
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        
                        Picker("Wrapper", selection: $wrapper) {
                            ForEach(HtmlWrapper.allCases) { w in
                                Text(w.rawValue).tag(w)
                            }
                        }
                        .frame(maxWidth: 180)
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Start with 'Lorem ipsum dolor sit amet...'", isOn: $startWithLorem)
                            .toggleStyle(.checkbox)
                        
                        Spacer()
                        
                        Button {
                            generate()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Stats Badges
                HStack(spacing: 12) {
                    metricBadge(label: "Words", value: "\(wordCount)")
                    metricBadge(label: "Characters", value: "\(generatedText.count)")
                    metricBadge(label: "Reading Time", value: readingTime)
                    Spacer()
                    
                    Button {
                        ClipboardHelper.copy(generatedText)
                        appState.showToast("Copied Lorem Ipsum text")
                    } label: {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(generatedText.isEmpty)
                }
                
                // Output Editor
                TextEditor(text: $generatedText)
                    .font(.system(.body, design: .serif))
                    .frame(minHeight: 320)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            if generatedText.isEmpty {
                generate()
            }
        }
    }
    
    // MARK: - Generation Logic
    private func generate() {
        switch unit {
        case .words:
            var words: [String] = []
            if startWithLorem {
                let prefix = ["Lorem", "ipsum", "dolor", "sit", "amet"]
                words.append(contentsOf: prefix.prefix(count))
            }
            while words.count < count {
                words.append(latinWords.randomElement() ?? "lorem")
            }
            let res = words.joined(separator: " ")
            generatedText = wrapText(res)
            
        case .sentences:
            var sentences: [String] = []
            for i in 0..<count {
                if i == 0 && startWithLorem {
                    sentences.append("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                } else {
                    sentences.append(randomSentence())
                }
            }
            let res = sentences.joined(separator: " ")
            generatedText = wrapText(res)
            
        case .paragraphs:
            var paras: [String] = []
            for i in 0..<count {
                if i == 0 && startWithLorem {
                    let first = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
                    paras.append(first)
                } else {
                    paras.append(randomParagraph())
                }
            }
            if wrapper == .pTag {
                generatedText = paras.map { "<p>\($0)</p>" }.joined(separator: "\n\n")
            } else if wrapper == .liTag {
                generatedText = "<ul>\n" + paras.map { "  <li>\($0)</li>" }.joined(separator: "\n") + "\n</ul>"
            } else {
                generatedText = paras.joined(separator: "\n\n")
            }
            
        case .bullets:
            var items: [String] = []
            for i in 0..<count {
                if i == 0 && startWithLorem {
                    items.append("Lorem ipsum dolor sit amet")
                } else {
                    items.append(randomSentence().trimmingCharacters(in: CharacterSet(charactersIn: ".")))
                }
            }
            if wrapper == .liTag {
                generatedText = "<ul>\n" + items.map { "  <li>\($0)</li>" }.joined(separator: "\n") + "\n</ul>"
            } else {
                generatedText = items.map { "• \($0)" }.joined(separator: "\n")
            }
        }
    }
    
    private func wrapText(_ raw: String) -> String {
        switch wrapper {
        case .none: return raw
        case .pTag: return "<p>\(raw)</p>"
        case .liTag: return "<li>\(raw)</li>"
        }
    }
    
    private func randomSentence() -> String {
        let length = Int.random(in: 8...16)
        var w = (0..<length).map { _ in latinWords.randomElement() ?? "lorem" }
        if let first = w.first {
            w[0] = first.capitalized
        }
        return w.joined(separator: " ") + "."
    }
    
    private func randomParagraph() -> String {
        let sentences = Int.random(in: 4...7)
        return (0..<sentences).map { _ in randomSentence() }.joined(separator: " ")
    }
    
    private var wordCount: Int {
        generatedText.split(whereSeparator: { $0.isWhitespace }).count
    }
    
    private var readingTime: String {
        let mins = Double(wordCount) / 200.0
        if mins < 0.5 { return "< 1 min read" }
        return String(format: "%.1f min read", mins)
    }
    
    private func metricBadge(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(6)
    }
}
