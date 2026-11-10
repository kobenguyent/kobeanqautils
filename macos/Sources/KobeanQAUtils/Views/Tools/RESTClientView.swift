import SwiftUI

struct RESTClientView: View {
    @EnvironmentObject var appState: AppState
    
    enum HTTPMethod: String, CaseIterable, Identifiable {
        case GET, POST, PUT, PATCH, DELETE, HEAD
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .GET: return .green
            case .POST: return .blue
            case .PUT: return .orange
            case .PATCH: return .purple
            case .DELETE: return .red
            case .HEAD: return .gray
            }
        }
    }
    
    @State private var method: HTTPMethod = .GET
    @State private var urlString: String = "https://jsonplaceholder.typicode.com/todos/1"
    @State private var requestHeaders: String = "Content-Type: application/json\nAccept: application/json"
    @State private var requestBody: String = "{\n  \"title\": \"foo\",\n  \"body\": \"bar\",\n  \"userId\": 1\n}"
    
    @State private var isLoading: Bool = false
    @State private var statusCode: Int? = nil
    @State private var responseTimeMs: Double? = nil
    @State private var responseHeaders: String = ""
    @State private var responseBody: String = ""
    @State private var errorMessage: String? = nil
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .restClient) {
                    method = .GET
                    urlString = "https://jsonplaceholder.typicode.com/todos/1"
                    requestBody = ""
                    responseBody = ""
                    statusCode = nil
                }
                
                // URL & Send Bar
                HStack(spacing: 8) {
                    Picker("", selection: $method) {
                        ForEach(HTTPMethod.allCases) { m in
                            Text(m.rawValue)
                                .fontWeight(.bold)
                                .foregroundColor(m.color)
                                .tag(m)
                        }
                    }
                    .frame(width: 100)
                    
                    TextField("Enter request URL", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Button(action: sendRequest) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 60)
                        } else {
                            Text("Send")
                                .fontWeight(.semibold)
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || urlString.isEmpty)
                }
                
                // Request Config Tabs (Headers, Body)
                VStack(alignment: .leading, spacing: 8) {
                    Picker("", selection: $selectedTab) {
                        Text("Headers").tag(0)
                        if method != .GET && method != .HEAD {
                            Text("Body").tag(1)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    
                    if selectedTab == 0 {
                        TextEditor(text: $requestHeaders)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 70)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    } else {
                        TextEditor(text: $requestBody)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 90)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                // Response Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Response")
                            .font(.headline)
                        
                        if let code = statusCode {
                            Text("\(code)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((200...299).contains(code) ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .foregroundColor((200...299).contains(code) ? .green : .red)
                                .cornerRadius(4)
                        }
                        
                        if let time = responseTimeMs {
                            Text(String(format: "%.0f ms", time))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Copy Response") {
                            appState.copyAndToast(responseBody)
                        }
                        .disabled(responseBody.isEmpty)
                    }
                    
                    if let err = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                    }
                    
                    TextEditor(text: .constant(responseBody.isEmpty ? "Press Send to execute request..." : responseBody))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
    
    private func sendRequest() {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid URL."
            return
        }
        
        isLoading = true
        errorMessage = nil
        statusCode = nil
        responseBody = ""
        responseTimeMs = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 15
        
        // Parse headers
        for line in requestHeaders.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                request.addValue(val, forHTTPHeaderField: key)
            }
        }
        
        if method != .GET && method != .HEAD && !requestBody.isEmpty {
            request.httpBody = requestBody.data(using: .utf8)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            DispatchQueue.main.async {
                self.isLoading = false
                self.responseTimeMs = duration
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let http = response as? HTTPURLResponse {
                    self.statusCode = http.statusCode
                }
                
                if let data = data {
                    // Try to pretty-print JSON if possible
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes]),
                       let str = String(data: prettyData, encoding: .utf8) {
                        self.responseBody = str
                    } else if let raw = String(data: data, encoding: .utf8) {
                        self.responseBody = raw
                    } else {
                        self.responseBody = "[Binary Data: \(data.count) bytes]"
                    }
                }
            }
        }.resume()
    }
}
