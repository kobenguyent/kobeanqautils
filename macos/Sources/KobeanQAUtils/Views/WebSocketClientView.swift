import SwiftUI
import AppKit

struct WebSocketMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: Direction
    let content: String
    let byteCount: Int
    
    enum Direction {
        case inbound
        case outbound
        case system
    }
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .secondary
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
}

final class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var status: ConnectionStatus = .disconnected
    @Published var messages: [WebSocketMessage] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    
    override init() {
        super.init()
    }
    
    func connect(urlString: String) {
        guard let url = URL(string: urlString) else {
            status = .error("Invalid URL")
            return
        }
        
        disconnect()
        status = .connecting
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        if case .connected = status {
            addSystemMessage("Connection closed.")
        }
        status = .disconnected
    }
    
    func send(text: String) {
        guard let task = webSocketTask, case .connected = status else { return }
        let msg = URLSessionWebSocketTask.Message.string(text)
        task.send(msg) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addSystemMessage("Send error: \(error.localizedDescription)")
                } else {
                    let out = WebSocketMessage(timestamp: Date(), direction: .outbound, content: text, byteCount: text.utf8.count)
                    self?.messages.append(out)
                }
            }
        }
    }
    
    func sendPing() {
        guard let task = webSocketTask, case .connected = status else { return }
        let start = Date()
        task.sendPing { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addSystemMessage("Ping failed: \(error.localizedDescription)")
                } else {
                    let latency = Int(Date().timeIntervalSince(start) * 1000)
                    self?.addSystemMessage("Pong received in \(latency) ms")
                }
            }
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        let inMsg = WebSocketMessage(timestamp: Date(), direction: .inbound, content: text, byteCount: text.utf8.count)
                        self.messages.append(inMsg)
                    case .data(let data):
                        let text = String(data: data, encoding: .utf8) ?? "<Binary data: \(data.count) bytes>"
                        let inMsg = WebSocketMessage(timestamp: Date(), direction: .inbound, content: text, byteCount: data.count)
                        self.messages.append(inMsg)
                    @unknown default:
                        break
                    }
                    self.listenForMessages()
                    
                case .failure(let error):
                    if case .connected = self.status {
                        self.status = .error(error.localizedDescription)
                        self.addSystemMessage("Receive error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func addSystemMessage(_ text: String) {
        let msg = WebSocketMessage(timestamp: Date(), direction: .system, content: text, byteCount: text.utf8.count)
        messages.append(msg)
    }
    
    // MARK: - Delegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.status = .connected
            self.addSystemMessage("Connected successfully! Protocol: \(String(describing: `protocol` ?? "default"))")
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "None"
            self.status = .disconnected
            self.addSystemMessage("Disconnected (Code: \(closeCode.rawValue), Reason: \(reasonStr))")
        }
    }
}

struct WebSocketClientView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var manager = WebSocketManager()
    
    @State private var urlString: String = "wss://echo.websocket.org"
    @State private var messageToSend: String = "{\"event\": \"ping\", \"timestamp\": 1700000000}"
    @State private var autoScroll: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .websocketClient)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Connection Bar
            HStack(spacing: 12) {
                TextField("ws:// or wss:// URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                statusPill
                
                if case .connected = manager.status {
                    Button("Ping") {
                        manager.sendPing()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Disconnect") {
                        manager.disconnect()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else if case .connecting = manager.status {
                    Button("Cancel") {
                        manager.disconnect()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Connect") {
                        manager.connect(urlString: urlString)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            
            // Message Log & Inspector
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Messages (\(manager.messages.count))")
                        .font(.headline)
                    
                    Spacer()
                    
                    Toggle("Auto-Scroll", isOn: $autoScroll)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Button("Clear") {
                        manager.messages.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            if manager.messages.isEmpty {
                                Text("No messages yet. Connect to a WebSocket server to view traffic.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(manager.messages) { msg in
                                    messageRow(msg)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(12)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    .onChange(of: manager.messages.count) { _ in
                        if autoScroll, let last = manager.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Composer Box
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Send Message")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("JSON Sample") {
                        messageToSend = "{\n  \"action\": \"test\",\n  \"payload\": {\n    \"device\": \"macOS\",\n    \"timestamp\": \(Int(Date().timeIntervalSince1970))\n  }\n}"
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    TextEditor(text: $messageToSend)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 70)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    
                    Button {
                        manager.send(text: messageToSend)
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                            .frame(minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(messageToSend.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isNotConnected)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var isNotConnected: Bool {
        if case .connected = manager.status { return false }
        return true
    }
    
    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(manager.status.color)
                .frame(width: 8, height: 8)
            Text(manager.status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(manager.status.color.opacity(0.12))
        .cornerRadius(12)
    }
    
    private func messageRow(_ msg: WebSocketMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Direction Badge
            switch msg.direction {
            case .inbound:
                Text("IN")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            case .outbound:
                Text("OUT")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            case .system:
                Text("SYS")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)
            }
            
            Text(timeFormatter.string(from: msg.timestamp))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(msg.content)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(4)
                .textSelection(.enabled)
            
            Spacer()
            
            Text("\(msg.byteCount) B")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
            
            Button {
                ClipboardHelper.copy(msg.content)
                appState.showToast("Copied message")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(rowBg(for: msg.direction))
        .cornerRadius(6)
    }
    
    private func rowBg(for dir: WebSocketMessage.Direction) -> Color {
        switch dir {
        case .inbound: return Color.green.opacity(0.04)
        case .outbound: return Color.blue.opacity(0.04)
        case .system: return Color.primary.opacity(0.02)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }
}
