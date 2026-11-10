import SwiftUI
import CryptoKit

struct EncryptionToolView: View {
    @EnvironmentObject private var appState: AppState
    
    enum OperationMode: String, CaseIterable, Identifiable {
        case encrypt = "Encrypt (AES-256-GCM)"
        case decrypt = "Decrypt (AES-256-GCM)"
        var id: String { rawValue }
    }
    
    enum OutputEncoding: String, CaseIterable, Identifiable {
        case base64 = "Base64"
        case hex = "Hexadecimal"
        var id: String { rawValue }
    }
    
    @State private var mode: OperationMode = .encrypt
    @State private var encoding: OutputEncoding = .base64
    @State private var passphrase: String = "kobean-super-secret-key-2026"
    @State private var showPassphrase: Bool = false
    @State private var inputContent: String = "Hello, KobeanQAUtils native security engine! Confidential QA payload."
    @State private var outputContent: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .encryptionTool)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        Picker("Operation", selection: $mode) {
                            ForEach(OperationMode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .frame(maxWidth: 240)
                        .onChange(of: mode) { _ in
                            swapInputOutput()
                        }
                        
                        Picker("Encoding", selection: $encoding) {
                            ForEach(OutputEncoding.allCases) { e in
                                Text(e.rawValue).tag(e)
                            }
                        }
                        .frame(maxWidth: 180)
                        
                        Spacer()
                        
                        Button {
                            executeCrypto()
                        } label: {
                            Label(mode == .encrypt ? "Encrypt Text" : "Decrypt Text", systemImage: mode == .encrypt ? "lock.fill" : "lock.open.fill")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    
                    Divider()
                    
                    // Secret Key Bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Secret Key / Passphrase")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button("Generate Strong Key") {
                                passphrase = generateRandomPassphrase()
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                        
                        HStack {
                            if showPassphrase {
                                TextField("Enter passphrase", text: $passphrase)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                SecureField("Enter passphrase", text: $passphrase)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            }
                            
                            Button {
                                showPassphrase.toggle()
                            } label: {
                                Image(systemName: showPassphrase ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Error Alert
                if !errorMessage.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Input Pane
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(mode == .encrypt ? "Plaintext Input" : "Ciphertext Input")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Clear") {
                            inputContent = ""
                            outputContent = ""
                            errorMessage = ""
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    
                    TextEditor(text: $inputContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                }
                
                // Output Pane
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(mode == .encrypt ? "AES-GCM Ciphertext (Nonce + Cipher + Tag)" : "Decrypted Plaintext")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            ClipboardHelper.copy(outputContent)
                            appState.showToast("Copied output")
                        } label: {
                            Label("Copy Result", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .disabled(outputContent.isEmpty)
                    }
                    
                    TextEditor(text: $outputContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(24)
        }
        .onAppear {
            if outputContent.isEmpty {
                executeCrypto()
            }
        }
    }
    
    // MARK: - Crypto Operations
    private func executeCrypto() {
        errorMessage = ""
        guard !passphrase.isEmpty else {
            errorMessage = "Please enter a passphrase/key."
            return
        }
        guard !inputContent.isEmpty else {
            outputContent = ""
            return
        }
        
        let symKey = deriveKey(from: passphrase)
        
        if mode == .encrypt {
            do {
                let dataToEncrypt = Data(inputContent.utf8)
                let sealedBox = try AES.GCM.seal(dataToEncrypt, using: symKey)
                guard let combined = sealedBox.combined else {
                    errorMessage = "Failed to bundle sealed box"
                    return
                }
                
                if encoding == .base64 {
                    outputContent = combined.base64EncodedString()
                } else {
                    outputContent = combined.map { String(format: "%02x", $0) }.joined()
                }
                appState.showToast("Encrypted successfully")
            } catch {
                errorMessage = "Encryption failed: \(error.localizedDescription)"
            }
        } else {
            // Decrypt
            do {
                let rawCipherData: Data
                if encoding == .base64 {
                    guard let d = Data(base64Encoded: inputContent.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                        errorMessage = "Invalid Base64 format in ciphertext."
                        return
                    }
                    rawCipherData = d
                } else {
                    let hex = inputContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let d = dataFromHex(hex) else {
                        errorMessage = "Invalid Hex format in ciphertext."
                        return
                    }
                    rawCipherData = d
                }
                
                let sealedBox = try AES.GCM.SealedBox(combined: rawCipherData)
                let decryptedData = try AES.GCM.open(sealedBox, using: symKey)
                guard let plain = String(data: decryptedData, encoding: .utf8) else {
                    errorMessage = "Decrypted bytes are not valid UTF-8 string."
                    return
                }
                outputContent = plain
                appState.showToast("Decrypted successfully")
            } catch {
                errorMessage = "Authentication failed: invalid key or tampered ciphertext."
            }
        }
    }
    
    private func swapInputOutput() {
        if !outputContent.isEmpty && errorMessage.isEmpty {
            inputContent = outputContent
            outputContent = ""
        }
    }
    
    private func deriveKey(from pass: String) -> SymmetricKey {
        let hash = SHA256.hash(data: Data(pass.utf8))
        return SymmetricKey(data: hash)
    }
    
    private func dataFromHex(_ hex: String) -> Data? {
        var data = Data()
        var temp = ""
        for char in hex {
            temp.append(char)
            if temp.count == 2 {
                guard let byte = UInt8(temp, radix: 16) else { return nil }
                data.append(byte)
                temp = ""
            }
        }
        return data
    }
    
    private func generateRandomPassphrase() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*-_"
        return String((0..<24).map { _ in chars.randomElement()! })
    }
}
