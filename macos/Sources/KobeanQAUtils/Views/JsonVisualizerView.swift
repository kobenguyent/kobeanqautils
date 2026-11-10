import SwiftUI
import AppKit

enum JSONNodeValue {
    case object([(String, JSONNode)])
    case array([JSONNode])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

struct JSONNode: Identifiable {
    let id = UUID()
    let key: String?
    let value: JSONNodeValue
    let path: String
    var isExpanded: Bool = true
}

struct JsonTreeNodeRow: View {
    let node: JSONNode
    let indent: CGFloat
    @Binding var selectedPath: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                // Indent
                if indent > 0 {
                    Spacer().frame(width: indent)
                }
                
                // Key and Type
                switch node.value {
                case .object(let pairs):
                    Text("{ }")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.purple)
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                    }
                    Text("{\(pairs.count) keys}")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                case .array(let items):
                    Text("[ ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.orange)
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                    }
                    Text("[\(items.count) items]")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                case .string(let s):
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    Text("\"\(s)\"")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                case .number(let n):
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    Text("\(n.formatted())")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.blue)
                case .boolean(let b):
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    Text(b ? "true" : "false")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(b ? .green : .red)
                case .null:
                    if let k = node.key {
                        Text(k + ":")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    Text("null")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedPath = node.path
            }
            
            // Nested Children
            switch node.value {
            case .object(let pairs):
                ForEach(pairs, id: \.1.id) { pair in
                    JsonTreeNodeRow(node: pair.1, indent: indent + 16, selectedPath: $selectedPath)
                }
            case .array(let items):
                ForEach(items) { item in
                    JsonTreeNodeRow(node: item, indent: indent + 16, selectedPath: $selectedPath)
                }
            default:
                EmptyView()
            }
        }
    }
}

struct JsonVisualizerView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var jsonInput: String = """
{
  "project": "KobeanQAUtils",
  "version": "1.2.0",
  "release": {
    "isNative": true,
    "framework": "SwiftUI",
    "architecture": "arm64"
  },
  "modules": [
    { "id": "converters", "count": 7, "status": "active" },
    { "id": "network", "count": 4, "status": "active" },
    { "id": "security", "count": 5, "status": "active" }
  ],
  "author": {
    "name": "Kobean QA Team",
    "website": "https://github.com/kobenguyent/kobeanqautils"
  }
}
"""
    @State private var searchFilter: String = ""
    @State private var parsedRoot: JSONNode?
    @State private var selectedPath: String = ""
    @State private var parseError: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .jsonVisualizer)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Search & Selected Path Bar
            HStack(spacing: 12) {
                TextField("Search JSON keys or values...", text: $searchFilter)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                
                if !selectedPath.isEmpty {
                    HStack(spacing: 6) {
                        Text("Path:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedPath)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        
                        Button {
                            ClipboardHelper.copy(selectedPath)
                            appState.showToast("Copied JSON path: \(selectedPath)")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                Button("Parse Tree") {
                    parseJson()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane: Editor & Interactive Tree
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Left: Raw JSON Editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Raw JSON Input")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $jsonInput)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .onChange(of: jsonInput) { _ in parseJson() }
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Right: Tree Visualizer
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Interactive Node Tree")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                if let root = parsedRoot {
                                    JsonTreeNodeRow(node: root, indent: 0, selectedPath: $selectedPath)
                                } else if !parseError.isEmpty {
                                    Text(parseError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding()
                                } else {
                                    Text("Enter valid JSON to inspect tree")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                            .padding(10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: .controlBackgroundColor))
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
            parseJson()
        }
    }
    
    // MARK: - JSON Parser
    private func parseJson() {
        parseError = ""
        guard let data = jsonInput.data(using: .utf8) else {
            parseError = "Invalid string encoding"
            parsedRoot = nil
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            parsedRoot = buildNode(key: nil, value: jsonObject, path: "$")
        } catch {
            parseError = error.localizedDescription
            parsedRoot = nil
        }
    }
    
    private func buildNode(key: String?, value: Any, path: String) -> JSONNode {
        if let dict = value as? [String: Any] {
            let sortedKeys = dict.keys.sorted()
            let pairs: [(String, JSONNode)] = sortedKeys.map { k in
                let childPath = path == "$" ? k : "\(path).\(k)"
                let child = buildNode(key: k, value: dict[k]!, path: childPath)
                return (k, child)
            }
            return JSONNode(key: key, value: .object(pairs), path: path)
        } else if let array = value as? [Any] {
            let items: [JSONNode] = array.enumerated().map { idx, element in
                let childPath = "\(path)[\(idx)]"
                return buildNode(key: "[\(idx)]", value: element, path: childPath)
            }
            return JSONNode(key: key, value: .array(items), path: path)
        } else if let s = value as? String {
            return JSONNode(key: key, value: .string(s), path: path)
        } else if let n = value as? NSNumber {
            // Check if boolean (CFBoolean)
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return JSONNode(key: key, value: .boolean(n.boolValue), path: path)
            } else {
                return JSONNode(key: key, value: .number(n.doubleValue), path: path)
            }
        } else if value is NSNull {
            return JSONNode(key: key, value: .null, path: path)
        } else {
            return JSONNode(key: key, value: .string(String(describing: value)), path: path)
        }
    }
}
