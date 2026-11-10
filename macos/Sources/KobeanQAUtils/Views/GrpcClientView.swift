import SwiftUI
import AppKit

struct GrpcClientView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var serverUrl: String = "https://api.example.com"
    @State private var serviceName: String = "UserService"
    @State private var methodName: String = "GetUser"
    @State private var metadataText: String = "authorization: Bearer token123\nx-client-version: 1.2.0"
    @State private var requestPayload: String = "{\n  \"userId\": \"usr_492048\",\n  \"includeProfile\": true\n}"
    
    @State private var responseText: String = ""
    @State private var responseStatus: String = ""
    @State private var responseTimeMs: Int = 0
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .grpcClient)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Server & RPC Endpoint Bar
            HStack(spacing: 12) {
                Text("gRPC")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(6)
                
                TextField("Server URL", text: $serverUrl)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                
                TextField("Service", text: $serviceName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)
                
                Text("/")
                    .foregroundColor(.secondary)
                
                TextField("Method", text: $methodName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)
                
                Spacer()
                
                Button {
                    invokeGrpc()
                } label: {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Label("Invoke RPC", systemImage: "bolt.fill")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || serverUrl.isEmpty || serviceName.isEmpty || methodName.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane: Request & Response
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Left: Request Payload & Metadata
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Metadata / Custom Headers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $metadataText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 60)
                            .padding(4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        
                        Text("Protobuf JSON Request Body")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $requestPayload)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
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
                                    .background(responseStatus.contains("OK") ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                    .foregroundColor(responseStatus.contains("OK") ? .green : .red)
                                    .cornerRadius(4)
                                
                                Text("\(responseTimeMs) ms")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button {
                                ClipboardHelper.copy(responseText)
                                appState.showToast("Copied gRPC response")
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
    
    // MARK: - RPC Invocation
    private func invokeGrpc() {
        let fullPath = "\(serverUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/\(serviceName)/\(methodName)"
        guard let url = URL(string: fullPath) else {
            responseText = "// Error: Invalid gRPC endpoint URL: \(fullPath)"
            return
        }
        
        isLoading = true
        responseText = "Invoking RPC method..."
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/grpc-web+proto, application/json", forHTTPHeaderField: "Accept")
        
        for line in metadataText.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                req.setValue(parts[1], forHTTPHeaderField: parts[0])
            }
        }
        
        req.httpBody = requestPayload.data(using: .utf8)
        
        let start = Date()
        URLSession.shared.dataTask(with: req) { data, response, error in
            let duration = Int(Date().timeIntervalSince(start) * 1000)
            DispatchQueue.main.async {
                self.isLoading = false
                self.responseTimeMs = duration
                
                if let http = response as? HTTPURLResponse {
                    let grpcStatus = http.allHeaderFields["grpc-status"] as? String ?? "\(http.statusCode)"
                    self.responseStatus = grpcStatus == "0" || http.statusCode == 200 ? "0 (OK)" : "Status \(grpcStatus)"
                }
                
                if let error = error {
                    self.responseText = "// gRPC Error: \(error.localizedDescription)\n// Target: \(fullPath)"
                    return
                }
                
                guard let data = data else {
                    self.responseText = "// Empty gRPC response payload."
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let str = String(data: pretty, encoding: .utf8) {
                    self.responseText = str
                } else {
                    self.responseText = String(data: data, encoding: .utf8) ?? "<Binary gRPC bytes: \(data.count) bytes>"
                }
            }
        }.resume()
    }
}
