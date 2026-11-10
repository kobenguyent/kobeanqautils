import SwiftUI
import AppKit

struct CollectionRequestItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var method: String
    var url: String
    var folder: String
    var headers: [String: String]
    var body: String
    var description: String
}

struct CollectionManagerView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var rawJson: String = ""
    @State private var collectionName: String = "E-Commerce QA Test API"
    @State private var requests: [CollectionRequestItem] = []
    @State private var selectedRequest: CollectionRequestItem? = nil
    @State private var searchText: String = ""
    @State private var selectedMethodFilter: String = "ALL"
    @State private var generatedExport: String = ""
    @State private var showExportSheet: Bool = false
    @State private var errorMessage: String? = nil
    
    let httpMethods = ["ALL", "GET", "POST", "PUT", "DELETE", "PATCH"]
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .collectionManager, onReset: loadSampleCollection)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            HSplitView {
                // Left: Collections & Requests Tree
                VStack(spacing: 8) {
                    // Top controls
                    HStack {
                        Button(action: importCollectionFile) {
                            Label("Import JSON", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: loadSampleCollection) {
                            Label("Sample", systemImage: "sparkles")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Text("\(filteredRequests.count) requests")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    
                    // Filter bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Filter requests...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 10)
                    
                    // Method filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(httpMethods, id: \.self) { method in
                                Button(action: { selectedMethodFilter = method }) {
                                    Text(method)
                                        .font(.caption2)
                                        .fontWeight(selectedMethodFilter == method ? .bold : .regular)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(selectedMethodFilter == method ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Divider()
                    
                    // List of requests grouped by folder
                    List(selection: $selectedRequest) {
                        ForEach(groupedFolders.keys.sorted(), id: \.self) { folderName in
                            Section(header: Label(folderName, systemImage: "folder.fill")) {
                                ForEach(groupedFolders[folderName] ?? []) { item in
                                    HStack(spacing: 8) {
                                        methodBadge(item.method)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text(item.url)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .tag(item)
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
                
                // Right: Request Detail Inspector & Exporter
                VStack(spacing: 0) {
                    if let req = selectedRequest {
                        requestInspectorView(req)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text("Select an API Request to Inspect")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Parse Postman v2.1 or Insomnia collections to generate cURL, Swift code, and review headers.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 420)
            }
        }
        .onAppear {
            if requests.isEmpty {
                loadSampleCollection()
            }
        }
    }
    
    // MARK: - Filtered Requests
    private var filteredRequests: [CollectionRequestItem] {
        requests.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.url.localizedCaseInsensitiveContains(searchText) ||
                item.folder.localizedCaseInsensitiveContains(searchText)
            
            let matchesMethod = selectedMethodFilter == "ALL" || item.method.uppercased() == selectedMethodFilter
            return matchesSearch && matchesMethod
        }
    }
    
    private var groupedFolders: [String: [CollectionRequestItem]] {
        Dictionary(grouping: filteredRequests, by: { $0.folder.isEmpty ? "Root" : $0.folder })
    }
    
    // MARK: - Badge UI
    @ViewBuilder
    private func methodBadge(_ method: String) -> some View {
        let color: Color = {
            switch method.uppercased() {
            case "GET": return .blue
            case "POST": return .green
            case "PUT": return .orange
            case "DELETE": return .red
            case "PATCH": return .purple
            default: return .gray
            }
        }()
        
        Text(method.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(3)
    }
    
    // MARK: - Request Inspector
    @ViewBuilder
    private func requestInspectorView(_ item: CollectionRequestItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Endpoint Header
                HStack(spacing: 10) {
                    methodBadge(item.method)
                    Text(item.url)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Button(action: {
                        ClipboardHelper.copy(generateCurl(for: item))
                        appState.showToast("cURL copied to clipboard")
                    }) {
                        Label("Copy cURL", systemImage: "terminal")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Description if any
                if !item.description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(item.description)
                            .font(.subheadline)
                    }
                }
                
                // Headers Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Headers (\(item.headers.count))")
                        .font(.headline)
                    
                    if item.headers.isEmpty {
                        Text("No custom headers defined")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(item.headers.keys.sorted(), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .frame(width: 150, alignment: .leading)
                                    Text(item.headers[key] ?? "")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                Divider()
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }
                
                // Request Body Section
                if !item.body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Request Body (JSON)")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                ClipboardHelper.copy(item.body)
                                appState.showToast("Body copied")
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Text(item.body)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                
                // Code Snippets (Swift URLSession)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Swift URLSession Code")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            ClipboardHelper.copy(generateSwiftCode(for: item))
                            appState.showToast("Swift code copied")
                        }) {
                            Label("Copy Code", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Text(generateSwiftCode(for: item))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Code Generation Helpers
    private func generateCurl(for item: CollectionRequestItem) -> String {
        var curl = "curl -X \(item.method.uppercased()) \"\(item.url)\""
        for (k, v) in item.headers {
            curl += " \\\n  -H \"\(k): \(v)\""
        }
        if !item.body.isEmpty {
            let escaped = item.body.replacingOccurrences(of: "\"", with: "\\\"")
            curl += " \\\n  -d \"\(escaped)\""
        }
        return curl
    }
    
    private func generateSwiftCode(for item: CollectionRequestItem) -> String {
        var code = """
        guard let url = URL(string: "\(item.url)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "\(item.method.uppercased())"
        
        """
        for (k, v) in item.headers {
            code += "request.setValue(\"\(v)\", forHTTPHeaderField: \"\(k)\")\n"
        }
        if !item.body.isEmpty {
            code += """
            request.httpBody = \"\"\"
            \(item.body)
            \"\"\".data(using: .utf8)
            
            """
        }
        code += """
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code:", httpResponse.statusCode)
        }
        """
        return code
    }
    
    // MARK: - Import & Parse
    private func importCollectionFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                if let str = String(data: data, encoding: .utf8) {
                    parseCollectionJson(str)
                }
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }
    
    private func parseCollectionJson(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            errorMessage = "Invalid JSON structure."
            return
        }
        
        var parsed: [CollectionRequestItem] = []
        let info = json["info"] as? [String: Any]
        collectionName = info?["name"] as? String ?? "Imported Collection"
        
        if let items = json["item"] as? [[String: Any]] {
            parseItems(items, folderPath: "", results: &parsed)
        }
        
        if !parsed.isEmpty {
            requests = parsed
            selectedRequest = parsed.first
            appState.showToast("Loaded \(parsed.count) requests from collection")
        } else {
            errorMessage = "No valid requests found in collection JSON."
        }
    }
    
    private func parseItems(_ items: [[String: Any]], folderPath: String, results: inout [CollectionRequestItem]) {
        for item in items {
            let name = item["name"] as? String ?? "Unnamed Request"
            if let subItems = item["item"] as? [[String: Any]] {
                // Folder
                let nextFolder = folderPath.isEmpty ? name : "\(folderPath) / \(name)"
                parseItems(subItems, folderPath: nextFolder, results: &results)
            } else if let requestDict = item["request"] as? [String: Any] {
                // Request
                let method = requestDict["method"] as? String ?? "GET"
                var urlStr = ""
                if let urlDict = requestDict["url"] as? [String: Any], let raw = urlDict["raw"] as? String {
                    urlStr = raw
                } else if let raw = requestDict["url"] as? String {
                    urlStr = raw
                }
                
                var headers: [String: String] = [:]
                if let headerArr = requestDict["header"] as? [[String: Any]] {
                    for h in headerArr {
                        if let k = h["key"] as? String, let v = h["value"] as? String {
                            headers[k] = v
                        }
                    }
                }
                
                var bodyStr = ""
                if let bodyDict = requestDict["body"] as? [String: Any], let raw = bodyDict["raw"] as? String {
                    bodyStr = raw
                }
                
                let desc = requestDict["description"] as? String ?? ""
                
                results.append(CollectionRequestItem(
                    name: name,
                    method: method,
                    url: urlStr,
                    folder: folderPath,
                    headers: headers,
                    body: bodyStr,
                    description: desc
                ))
            }
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleCollection() {
        requests = [
            CollectionRequestItem(
                name: "User Login",
                method: "POST",
                url: "https://api.example.com/v1/auth/login",
                folder: "Authentication",
                headers: ["Content-Type": "application/json", "Accept": "application/json"],
                body: "{\n  \"email\": \"test.user@qa.example.com\",\n  \"password\": \"P@ssw0rd2026!\"\n}",
                description: "Authenticates client and returns Bearer JWT accessToken & refreshToken"
            ),
            CollectionRequestItem(
                name: "Get User Profile",
                method: "GET",
                url: "https://api.example.com/v1/users/me",
                folder: "Authentication",
                headers: ["Authorization": "Bearer {{jwt_token}}", "Accept": "application/json"],
                body: "",
                description: "Returns currently authenticated user profile and permissions"
            ),
            CollectionRequestItem(
                name: "List All Products",
                method: "GET",
                url: "https://api.example.com/v1/products?limit=20&page=1&status=active",
                folder: "Catalog",
                headers: ["Accept": "application/json"],
                body: "",
                description: "Retrieve paginated list of catalog products"
            ),
            CollectionRequestItem(
                name: "Create Product",
                method: "POST",
                url: "https://api.example.com/v1/products",
                folder: "Catalog",
                headers: ["Content-Type": "application/json", "Authorization": "Bearer {{admin_token}}"],
                body: "{\n  \"sku\": \"PROD-8821\",\n  \"name\": \"Wireless QA Controller\",\n  \"price\": 49.99,\n  \"stock\": 150\n}",
                description: "Adds a new product item into store inventory"
            ),
            CollectionRequestItem(
                name: "Update Inventory Stock",
                method: "PUT",
                url: "https://api.example.com/v1/products/PROD-8821/stock",
                folder: "Catalog",
                headers: ["Content-Type": "application/json", "Authorization": "Bearer {{admin_token}}"],
                body: "{\n  \"quantityDelta\": 25,\n  \"reason\": \"Warehouse Restock\"\n}",
                description: "Adjust inventory quantities"
            ),
            CollectionRequestItem(
                name: "Create Checkout Order",
                method: "POST",
                url: "https://api.example.com/v1/orders",
                folder: "Orders & Checkout",
                headers: ["Content-Type": "application/json", "Authorization": "Bearer {{jwt_token}}"],
                body: "{\n  \"items\": [\n    {\"sku\": \"PROD-8821\", \"quantity\": 2}\n  ],\n  \"paymentMethod\": \"stripe_token_sample\"\n}",
                description: "Process new customer cart checkout"
            ),
            CollectionRequestItem(
                name: "Cancel Order",
                method: "DELETE",
                url: "https://api.example.com/v1/orders/ORD-90241",
                folder: "Orders & Checkout",
                headers: ["Authorization": "Bearer {{jwt_token}}"],
                body: "",
                description: "Cancels an unfulfilled pending order"
            )
        ]
        selectedRequest = requests.first
    }
}
