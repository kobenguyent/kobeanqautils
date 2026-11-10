import SwiftUI
import AppKit
import CryptoKit

struct FileProcessorView: View {
    @EnvironmentObject private var appState: AppState
    
    struct FileInfo {
        let name: String
        let path: String
        let sizeBytes: Int64
        let sha256: String
        let md5: String
        let mimeType: String
        let hexDump: String
        let base64Preview: String
        let lineEnding: String
    }
    
    @State private var fileInfo: FileInfo?
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .fileProcessor)
                
                // Select / Drop File Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fileInfo == nil ? "Select a file to inspect" : fileInfo!.name)
                            .font(.headline)
                        Text(fileInfo == nil ? "Inspect file metadata, binary hex dump, and CryptoKit checksums." : fileInfo!.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        chooseFile()
                    } label: {
                        Label("Choose File...", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                if let info = fileInfo {
                    // Metadata Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("File Metadata & Integrity")
                            .font(.headline)
                        
                        metaRow(label: "Size", value: "\(ByteCountFormatter.string(fromByteCount: info.sizeBytes, countStyle: .file)) (\(info.sizeBytes.formatted()) bytes)")
                        metaRow(label: "MIME / UTI", value: info.mimeType)
                        metaRow(label: "Line Endings", value: info.lineEnding)
                        metaRow(label: "SHA-256", value: info.sha256)
                        metaRow(label: "MD5", value: info.md5)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    
                    // Hex Dump & Base64 Inspector
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("", selection: $selectedTab) {
                            Text("Hex Dump").tag(0)
                            Text("Base64 Data URI").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 260)
                        
                        if selectedTab == 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Binary Inspection (First 1 KB)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Copy Hex") {
                                        ClipboardHelper.copy(info.hexDump)
                                        appState.showToast("Copied hex dump")
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }
                                
                                TextEditor(text: .constant(info.hexDump))
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(minHeight: 220)
                                    .padding(6)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .cornerRadius(8)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Base64 Data URI")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Copy Data URI") {
                                        ClipboardHelper.copy(info.base64Preview)
                                        appState.showToast("Copied Base64 URI")
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }
                                
                                TextEditor(text: .constant(info.base64Preview))
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(minHeight: 220)
                                    .padding(6)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(24)
        }
    }
    
    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                ClipboardHelper.copy(value)
                appState.showToast("Copied \(label)")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 3)
    }
    
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            inspect(url: url)
        }
    }
    
    private func inspect(url: URL) {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
        
        let sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        
        // Hex dump of first 1024 bytes
        let slice = data.prefix(1024)
        var dumpLines: [String] = []
        var offset = 0
        while offset < slice.count {
            let chunk = slice.dropFirst(offset).prefix(16)
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let paddedHex = hex.padding(toLength: 48, withPad: " ", startingAt: 0)
            let ascii = chunk.map { (32...126).contains($0) ? String(UnicodeScalar($0)) : "." }.joined()
            dumpLines.append(String(format: "%08X:  %@  |%@|", offset, paddedHex, ascii))
            offset += 16
        }
        
        let ext = url.pathExtension.lowercased()
        let mime = ext == "png" ? "image/png" : (ext == "jpg" || ext == "jpeg" ? "image/jpeg" : (ext == "json" ? "application/json" : "application/octet-stream"))
        let b64 = "data:\(mime);base64,\(data.prefix(100_000).base64EncodedString())"
        
        // Line ending check
        var lineEnding = "N/A (Binary)"
        if let text = String(data: data.prefix(4096), encoding: .utf8) {
            if text.contains("\r\n") {
                lineEnding = "Windows (CRLF - \\r\\n)"
            } else if text.contains("\n") {
                lineEnding = "Unix / macOS (LF - \\n)"
            }
        }
        
        fileInfo = FileInfo(
            name: url.lastPathComponent,
            path: url.path,
            sizeBytes: Int64(data.count),
            sha256: sha256,
            md5: md5,
            mimeType: mime,
            hexDump: dumpLines.joined(separator: "\n"),
            base64Preview: b64,
            lineEnding: lineEnding
        )
    }
}
