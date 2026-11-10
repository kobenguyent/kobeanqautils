import SwiftUI
import AppKit
import CryptoKit

struct TestFileGeneratorView: View {
    @EnvironmentObject private var appState: AppState
    
    enum FileFormat: String, CaseIterable, Identifiable {
        case text = "Plain Text (.txt)"
        case binary = "Binary Random (.bin)"
        case zeros = "Zero-Filled Binary (.dat)"
        case json = "Mock JSON (.json)"
        case csv = "Mock CSV (.csv)"
        var id: String { rawValue }
        
        var ext: String {
            switch self {
            case .text: return "txt"
            case .binary: return "bin"
            case .zeros: return "dat"
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    enum SizeUnit: String, CaseIterable, Identifiable {
        case kb = "KB"
        case mb = "MB"
        case bytes = "Bytes"
        var id: String { rawValue }
        
        var multiplier: Int {
            switch self {
            case .bytes: return 1
            case .kb: return 1024
            case .mb: return 1024 * 1024
            }
        }
    }
    
    @State private var format: FileFormat = .text
    @State private var sizeValue: Int = 1
    @State private var sizeUnit: SizeUnit = .mb
    @State private var customFileName: String = "test-sample-file"
    @State private var isGenerating: Bool = false
    @State private var lastGeneratedInfo: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .testFileGen)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("File Format")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $format) {
                                ForEach(FileFormat.allCases) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                        }
                        .frame(maxWidth: 220)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("File Size")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 8) {
                                TextField("Size", value: $sizeValue, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                
                                Picker("", selection: $sizeUnit) {
                                    ForEach(SizeUnit.allCases) { u in
                                        Text(u.rawValue).tag(u)
                                    }
                                }
                                .frame(width: 90)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Base File Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("File name", text: $customFileName)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 200)
                        }
                    }
                    
                    // Quick Presets
                    HStack(spacing: 8) {
                        Text("Presets:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        presetButton(label: "50 KB", size: 50, unit: .kb)
                        presetButton(label: "500 KB", size: 500, unit: .kb)
                        presetButton(label: "1 MB", size: 1, unit: .mb)
                        presetButton(label: "5 MB", size: 5, unit: .mb)
                        presetButton(label: "25 MB", size: 25, unit: .mb)
                        presetButton(label: "100 MB", size: 100, unit: .mb)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target Total Bytes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalBytes.formatted()) bytes (\(formattedByteSize))")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Button {
                            generateAndSave()
                        } label: {
                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Label("Generate & Save to Disk...", systemImage: "arrow.down.doc.fill")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating || totalBytes <= 0 || totalBytes > 250 * 1024 * 1024)
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Result Card
                if !lastGeneratedInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("File Generation Summary")
                                .font(.headline)
                        }
                        
                        Text(lastGeneratedInfo)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(24)
        }
    }
    
    private func presetButton(label: String, size: Int, unit: SizeUnit) -> some View {
        Button(label) {
            sizeValue = size
            sizeUnit = unit
        }
        .buttonStyle(.bordered)
        .font(.caption)
    }
    
    private var totalBytes: Int {
        max(1, sizeValue) * sizeUnit.multiplier
    }
    
    private var formattedByteSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    // MARK: - Generation & Streaming
    private func generateAndSave() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(customFileName).\(format.ext)"
        panel.prompt = "Save Test File"
        
        guard panel.runModal() == .OK, let fileUrl = panel.url else { return }
        
        isGenerating = true
        let bytesTarget = totalBytes
        let currentFormat = format
        
        DispatchQueue.global(qos: .userInitiated).async {
            FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: nil)
            guard let handle = try? FileHandle(forWritingTo: fileUrl) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.appState.showToast("Failed to create file handle")
                }
                return
            }
            
            var hasher = SHA256()
            var written = 0
            let chunkSize = min(64 * 1024, bytesTarget) // 64 KB chunks
            
            let chunkData: Data
            switch currentFormat {
            case .zeros:
                chunkData = Data(repeating: 0, count: chunkSize)
            case .binary:
                var rnd = [UInt8](repeating: 0, count: chunkSize)
                _ = SecRandomCopyBytes(kSecRandomDefault, chunkSize, &rnd)
                chunkData = Data(rnd)
            case .text:
                let sample = "KobeanQAUtils Test File Generator. Automated testing line for file size validation.\n"
                let repeatCount = (chunkSize / sample.utf8.count) + 1
                chunkData = Data(String(repeating: sample, count: repeatCount).utf8.prefix(chunkSize))
            case .json:
                let sample = "{\"id\":\"\(UUID().uuidString)\",\"event\":\"qa_test_payload\",\"value\":12345},\n"
                let repeatCount = (chunkSize / sample.utf8.count) + 1
                chunkData = Data(String(repeating: sample, count: repeatCount).utf8.prefix(chunkSize))
            case .csv:
                let sample = "\"\(UUID().uuidString)\",\"Test User\",\"test@example.com\",\"Approved\",100\n"
                let repeatCount = (chunkSize / sample.utf8.count) + 1
                chunkData = Data(String(repeating: sample, count: repeatCount).utf8.prefix(chunkSize))
            }
            
            while written < bytesTarget {
                let toWrite = min(chunkSize, bytesTarget - written)
                let slice = chunkData.prefix(toWrite)
                handle.write(slice)
                hasher.update(data: slice)
                written += toWrite
            }
            
            try? handle.close()
            let digest = hasher.finalize()
            let shaHex = digest.map { String(format: "%02x", $0) }.joined()
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.lastGeneratedInfo = """
                Location: \(fileUrl.path)
                Size:     \(written.formatted()) bytes (\(ByteCountFormatter.string(fromByteCount: Int64(written), countStyle: .file)))
                SHA-256:  \(shaHex)
                """
                self.appState.showToast("Test file generated successfully!")
            }
        }
    }
}
