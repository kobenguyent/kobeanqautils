import SwiftUI
import AppKit

struct GraphQLClientView: View {
    @EnvironmentObject private var appState: AppState
    
    enum TabSelection: String, CaseIterable, Identifiable {
        case query = "Query"
        case variables = "Variables"
        case headers = "Headers"
        var id: String { rawValue }
    }
    
    @State private var endpointUrl: String = "https://countries.trevorblades.com/graphql"
    @State private var selectedTab: TabSelection = .query
    
    @State private var queryText: String = """
query GetCountryDetails {
  country(code: "US") {
    name
    native
    capital
    currency
    emoji
    languages {
      code
      name
    }
  }
}
"""
    @State private var variablesText: String = "{\n  \"code\": \"US\"\n}"
    @State private var headersText: String = "Content-Type: application/json\nAccept: application/json"
    
    @State private var responseText: String = ""
    @State private var responseStatus: String = ""
    @State private var responseTimeMs: Int = 0
    @State private var responseSize: Int = 0
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .graphqlClient)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Endpoint URL Bar
            HStack(spacing: 12) {
                Text("POST")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .cornerRadius(6)
                
                TextField("https://api.example.com/graphql", text: $endpointUrl)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Button {
                    loadPreset("Countries")
                } label: {
                    Text("Sample Query")
                }
                .buttonStyle(.bordered)
                
                Button {
                    executeQuery()
                } label: {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Label("Execute", systemImage: "play.fill")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || endpointUrl.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane: Editor & Response
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Left: Query / Variables / Headers
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $selectedTab) {
                            ForEach(TabSelection.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        switch selectedTab {
                        case .query:
                            TextEditor(text: $queryText)
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        case .variables:
                            TextEditor(text: $variablesText)
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        case .headers:
                            TextEditor(text: $headersText)
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        }
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Right: Response Viewer
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Response")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if !responseStatus.isEmpty {
                                Text(responseStatus)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(responseStatus.contains("200") ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundColor(responseStatus.contains("200") ? .green : .orange)
                                    .cornerRadius(4)
                                
                                Text("\(responseTimeMs) ms")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text("\(responseSize) B")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button {
                                ClipboardHelper.copy(responseText)
                                appState.showToast("Copied GraphQL response")
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .disabled(responseText.isEmpty)
                        }
                        
                        TextEditor(text: $responseText)
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
    }
    
    // MARK: - Query Execution
    private func executeQuery() {
        guard let url = URL(string: endpointUrl) else {
            responseText = "// Error: Invalid endpoint URL"
            return
        }
        
        isLoading = true
        responseText = "Executing query..."
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Parse custom headers
        for line in headersText.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                request.setValue(parts[1], forHTTPHeaderField: parts[0])
            }
        }
        
        // Build JSON body
        var bodyDict: [String: Any] = ["query": queryText]
        if let varData = variablesText.data(using: .utf8),
           let varJson = try? JSONSerialization.jsonObject(with: varData) {
            bodyDict["variables"] = varJson
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)
        
        let start = Date()
        URLSession.shared.dataTask(with: request) { data, response, error in
            let duration = Int(Date().timeIntervalSince(start) * 1000)
            DispatchQueue.main.async {
                self.isLoading = false
                self.responseTimeMs = duration
                
                if let http = response as? HTTPURLResponse {
                    self.responseStatus = "HTTP \(http.statusCode)"
                }
                
                if let error = error {
                    self.responseText = "// Network Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.responseText = "// Empty response received."
                    return
                }
                
                self.responseSize = data.count
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let str = String(data: pretty, encoding: .utf8) {
                    self.responseText = str
                } else {
                    self.responseText = String(data: data, encoding: .utf8) ?? "<Binary response>"
                }
            }
        }.resume()
    }
    
    private func loadPreset(_ name: String) {
        endpointUrl = "https://countries.trevorblades.com/graphql"
        queryText = """
query GetCountryDetails {
  country(code: "US") {
    name
    capital
    currency
    emoji
    languages {
      code
      name
    }
  }
}
"""
        variablesText = "{}"
    }
}
