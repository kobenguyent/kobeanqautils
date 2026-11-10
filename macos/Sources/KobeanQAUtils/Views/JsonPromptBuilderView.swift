import SwiftUI
import AppKit

struct PromptMessageNode: Identifiable {
    let id = UUID()
    var role: String
    var content: String
}

struct JsonPromptBuilderView: View {
    @EnvironmentObject private var appState: AppState
    
    enum ProviderFormat: String, CaseIterable, Identifiable {
        case openai = "OpenAI (ChatCompletion)"
        case anthropic = "Anthropic (Claude)"
        case gemini = "Google (Gemini)"
        var id: String { rawValue }
    }
    
    @State private var provider: ProviderFormat = .openai
    @State private var modelName: String = "gpt-4o"
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 2048
    
    @State private var messages: [PromptMessageNode] = [
        PromptMessageNode(role: "system", content: "You are KobeanQAUtils Native AI Assistant. Generate concise test automation scripts."),
        PromptMessageNode(role: "user", content: "Write a Playwright test script verifying user checkout with a 20% discount voucher."),
        PromptMessageNode(role: "assistant", content: "Here is the verified test script using Page Object Model...")
    ]
    
    @State private var jsonOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .jsonPromptBuilder)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        Picker("Target API", selection: $provider) {
                            ForEach(ProviderFormat.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .frame(maxWidth: 240)
                        .onChange(of: provider) { _ in
                            updateDefaultModel()
                            renderJSON()
                        }
                        
                        TextField("Model", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 160)
                            .onChange(of: modelName) { _ in renderJSON() }
                        
                        HStack(spacing: 6) {
                            Text("Temp:")
                                .font(.caption)
                            Slider(value: $temperature, in: 0...1, step: 0.1)
                                .frame(width: 80)
                                .onChange(of: temperature) { _ in renderJSON() }
                            Text(String(format: "%.1f", temperature))
                                .font(.system(.caption, design: .monospaced))
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Messages List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Conversation Messages (\(messages.count))")
                            .font(.headline)
                        Spacer()
                        
                        Button {
                            messages.append(PromptMessageNode(role: "user", content: ""))
                            renderJSON()
                        } label: {
                            Label("Add Message", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ForEach($messages) { $msg in
                        HStack(alignment: .top, spacing: 10) {
                            Picker("", selection: $msg.role) {
                                Text("system").tag("system")
                                Text("user").tag("user")
                                Text("assistant").tag("assistant")
                            }
                            .frame(width: 105)
                            .onChange(of: msg.role) { _ in renderJSON() }
                            
                            TextEditor(text: $msg.content)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 50)
                                .padding(4)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                                .onChange(of: msg.content) { _ in renderJSON() }
                            
                            Button {
                                if let idx = messages.firstIndex(where: { $0.id == msg.id }) {
                                    messages.remove(at: idx)
                                    renderJSON()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                            .padding(.top, 4)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                
                // Export JSON
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Exported Provider JSON Payload")
                            .font(.headline)
                        Spacer()
                        
                        Button {
                            ClipboardHelper.copy(jsonOutput)
                            appState.showToast("Copied provider JSON payload")
                        } label: {
                            Label("Copy JSON", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    TextEditor(text: $jsonOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 240)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(24)
        }
        .onAppear {
            renderJSON()
        }
    }
    
    private func updateDefaultModel() {
        switch provider {
        case .openai: modelName = "gpt-4o"
        case .anthropic: modelName = "claude-3-5-sonnet-20241022"
        case .gemini: modelName = "gemini-1.5-flash"
        }
    }
    
    private func renderJSON() {
        var payload: [String: Any] = [:]
        
        switch provider {
        case .openai:
            payload["model"] = modelName
            payload["temperature"] = temperature
            payload["max_tokens"] = maxTokens
            payload["messages"] = messages.map { ["role": $0.role, "content": $0.content] }
            
        case .anthropic:
            payload["model"] = modelName
            payload["max_tokens"] = maxTokens
            let systemMsg = messages.first(where: { $0.role == "system" })?.content ?? ""
            if !systemMsg.isEmpty {
                payload["system"] = systemMsg
            }
            let convo = messages.filter { $0.role != "system" }.map { ["role": $0.role, "content": $0.content] }
            payload["messages"] = convo
            
        case .gemini:
            let contents = messages.map { msg -> [String: Any] in
                let geminiRole = msg.role == "assistant" ? "model" : "user"
                return ["role": geminiRole, "parts": [["text": msg.content]]]
            }
            payload["contents"] = contents
            payload["generationConfig"] = ["temperature": temperature, "maxOutputTokens": maxTokens]
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            jsonOutput = str
        }
    }
}
