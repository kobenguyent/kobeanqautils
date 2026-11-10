import SwiftUI

struct JSONFormatterView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var input: String = """
    {
      "name": "KobeanQAUtils",
      "version": "1.2.0",
      "native": true,
      "features": ["Base64", "JWT", "REST Client", "TOTP 2FA", "JSON"],
      "author": { "name": "KobeT", "email": "kobenguyent@gmail.com" }
    }
    """
    @State private var output: String = ""
    @State private var isValid: Bool = true
    @State private var errorMessage: String? = nil
    @State private var indentLevel: Int = 2
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .jsonFormatter) {
                    input = "{}"
                    format()
                }
                
                // Toolbar controls
                HStack(spacing: 12) {
                    Button(action: {
                        format()
                    }) {
                        Label("Prettify", systemImage: "text.alignleft")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        minify()
                    }) {
                        Label("Minify", systemImage: "arrow.right.to.line.compact")
                    }
                    .buttonStyle(.bordered)
                    
                    Picker("Indent:", selection: $indentLevel) {
                        Text("2 Spaces").tag(2)
                        Text("4 Spaces").tag(4)
                    }
                    .frame(width: 130)
                    .onChange(of: indentLevel) { _ in format() }
                    
                    Spacer()
                    
                    if isValid {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Valid JSON")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Invalid JSON")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Editors: Input & Output side-by-side or stacked
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Input")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Sample") {
                                input = """
                                {"user":{"id":42,"username":"kobet","roles":["qa","dev"]},"active":true}
                                """
                                format()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        TextEditor(text: $input)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                            .onChange(of: input) { _ in
                                format()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Formatted Output")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                appState.copyAndToast(output)
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .disabled(output.isEmpty)
                        }
                        
                        TextEditor(text: .constant(output))
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            format()
        }
    }
    
    private func format() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            output = ""
            isValid = true
            errorMessage = nil
            return
        }
        
        guard let data = trimmed.data(using: .utf8) else {
            isValid = false
            errorMessage = "Encoding error: cannot read UTF-8 data."
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            if var str = String(data: formattedData, encoding: .utf8) {
                if indentLevel == 4 {
                    // JSONSerialization uses 2 spaces by default; replace with 4 spaces
                    str = str.replacingOccurrences(of: "\n  ", with: "\n    ")
                }
                output = str
            }
            isValid = true
            errorMessage = nil
        } catch {
            isValid = false
            errorMessage = error.localizedDescription
            output = input
        }
    }
    
    private func minify() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.withoutEscapingSlashes])
            if let str = String(data: minifiedData, encoding: .utf8) {
                output = str
            }
            isValid = true
            errorMessage = nil
        } catch {
            isValid = false
            errorMessage = error.localizedDescription
        }
    }
}
