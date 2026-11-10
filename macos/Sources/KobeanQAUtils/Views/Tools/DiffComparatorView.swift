import SwiftUI

struct DiffComparatorView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var originalText: String = "function calculateTotal(items) {\n  let sum = 0;\n  for (let i = 0; i < items.length; i++) {\n    sum += items[i].price;\n  }\n  return sum;\n}"
    @State private var modifiedText: String = "function calculateTotal(items) {\n  // Optimized using reduce\n  return items.reduce((sum, item) => sum + item.price, 0);\n}"
    
    enum DiffType {
        case same, added, removed
        
        var color: Color {
            switch self {
            case .same: return .secondary.opacity(0.1)
            case .added: return .green.opacity(0.15)
            case .removed: return .red.opacity(0.15)
            }
        }
        
        var prefix: String {
            switch self {
            case .same: return "  "
            case .added: return "+ "
            case .removed: return "- "
            }
        }
    }
    
    struct DiffLine: Identifiable {
        let id = UUID()
        let type: DiffType
        let text: String
    }
    
    private var diffLines: [DiffLine] {
        let origLines = originalText.components(separatedBy: "\n")
        let modLines = modifiedText.components(separatedBy: "\n")
        
        var result: [DiffLine] = []
        let maxCount = max(origLines.count, modLines.count)
        
        for i in 0..<maxCount {
            let orig = (i < origLines.count) ? origLines[i] : nil
            let mod = (i < modLines.count) ? modLines[i] : nil
            
            if orig == mod, let text = orig {
                result.append(DiffLine(type: .same, text: text))
            } else {
                if let o = orig {
                    result.append(DiffLine(type: .removed, text: o))
                }
                if let m = mod {
                    result.append(DiffLine(type: .added, text: m))
                }
            }
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .diffComparator) {
                    originalText = ""
                    modifiedText = ""
                }
                
                // Editors
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Original Text")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $originalText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Modified Text")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $modifiedText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                    }
                }
                
                // Diff Results
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Line Diff Analysis")
                            .font(.headline)
                        Spacer()
                        let added = diffLines.filter { $0.type == .added }.count
                        let removed = diffLines.filter { $0.type == .removed }.count
                        Text("+\(added) added, -\(removed) removed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(diffLines) { line in
                            HStack(alignment: .top, spacing: 4) {
                                Text(line.type.prefix)
                                    .fontWeight(.bold)
                                    .foregroundColor(line.type == .added ? .green : (line.type == .removed ? .red : .secondary))
                                Text(line.text.isEmpty ? " " : line.text)
                                    .font(.system(.callout, design: .monospaced))
                                Spacer()
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(line.type.color)
                            .cornerRadius(4)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
}
