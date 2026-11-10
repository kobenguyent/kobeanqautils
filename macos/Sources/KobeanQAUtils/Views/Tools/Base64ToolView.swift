import SwiftUI

struct Base64ToolView: View {
    @EnvironmentObject var appState: AppState
    
    enum Mode: String, CaseIterable, Identifiable {
        case encode = "Encode"
        case decode = "Decode"
        var id: String { rawValue }
    }
    
    @State private var mode: Mode = .encode
    @State private var urlSafe: Bool = false
    @State private var input: String = "Hello, KobeanQAUtils!"
    @State private var errorMessage: String? = nil
    
    private var output: String {
        if input.isEmpty { return "" }
        switch mode {
        case .encode:
            guard let data = input.data(using: .utf8) else { return "" }
            var base64 = data.base64EncodedString()
            if urlSafe {
                base64 = base64.replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "="))
            }
            return base64
        case .decode:
            var normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
            if urlSafe {
                normalized = normalized.replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                let mod4 = normalized.count % 4
                if mod4 > 0 {
                    normalized += String(repeating: "=", count: 4 - mod4)
                }
            }
            guard let data = Data(base64Encoded: normalized) else {
                return "[Error: Invalid Base64 input string]"
            }
            guard let decoded = String(data: data, encoding: .utf8) else {
                return "[Error: Decoded binary data is not valid UTF-8 string (\(data.count) bytes)]"
            }
            return decoded
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .base64) {
                    input = ""
                }
                
                // Controls bar
                HStack(spacing: 16) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    
                    Toggle("URL-Safe Base64", isOn: $urlSafe)
                    
                    Spacer()
                    
                    Button("Swap") {
                        let prevOut = output
                        if !prevOut.hasPrefix("[Error:") && !prevOut.isEmpty {
                            input = prevOut
                            mode = (mode == .encode) ? .decode : .encode
                        }
                    }
                    .disabled(output.isEmpty || output.hasPrefix("[Error:"))
                }
                .padding(.horizontal, 4)
                
                // Input section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Input (\(input.count) characters)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let pasted = ClipboardHelper.paste() {
                            Button("Paste") {
                                input = pasted
                            }
                            .buttonStyle(.borderless)
                        }
                        if !input.isEmpty {
                            Button("Clear") {
                                input = ""
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    TextEditor(text: $input)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
                
                // Output section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Output (\(output.count) characters)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            appState.copyAndToast(output)
                        }) {
                            Label("Copy Output", systemImage: "doc.on.doc")
                        }
                        .disabled(output.isEmpty || output.hasPrefix("[Error:"))
                    }
                    
                    TextEditor(text: .constant(output))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
}
