import SwiftUI
import CryptoKit

struct HTPasswdGeneratorView: View {
    @EnvironmentObject private var appState: AppState
    
    enum HashAlgorithm: String, CaseIterable, Identifiable {
        case sha1 = "SHA-1 ({SHA})"
        case apr1 = "APR1-MD5"
        case plaintext = "Plaintext (dev only)"
        var id: String { rawValue }
    }
    
    @State private var username: String = "admin"
    @State private var password: String = "SecretPass123!"
    @State private var showPassword: Bool = false
    @State private var algorithm: HashAlgorithm = .sha1
    @State private var currentHash: String = ""
    @State private var htpasswdEntries: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .htpasswdGen)
                
                // Form Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("e.g. admin", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: username) { _ in computeHash() }
                        }
                        .frame(maxWidth: 220)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Random") {
                                    password = generateRandomPassword()
                                    computeHash()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                            
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("Password", text: $password)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.borderless)
                            }
                            .onChange(of: password) { _ in computeHash() }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Algorithm")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $algorithm) {
                                ForEach(HashAlgorithm.allCases) { a in
                                    Text(a.rawValue).tag(a)
                                }
                            }
                            .onChange(of: algorithm) { _ in computeHash() }
                        }
                        .frame(maxWidth: 200)
                    }
                    
                    Divider()
                    
                    // Single Output
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Entry:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(currentHash.isEmpty ? "<enter username & password>" : currentHash)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(currentHash.isEmpty ? .secondary : .primary)
                            
                            Spacer()
                            
                            Button {
                                htpasswdEntries.append(currentHash)
                                appState.showToast("Added to list")
                            } label: {
                                Label("Add to List", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                            .disabled(currentHash.isEmpty)
                            
                            Button {
                                ClipboardHelper.copy(currentHash)
                                appState.showToast("Copied htpasswd entry")
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(currentHash.isEmpty)
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Multi-User File Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(".htpasswd File Content (\(htpasswdEntries.count) users)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            htpasswdEntries.removeAll()
                        }
                        .buttonStyle(.borderless)
                        .disabled(htpasswdEntries.isEmpty)
                        
                        Button {
                            let text = htpasswdEntries.joined(separator: "\n")
                            ClipboardHelper.copy(text)
                            appState.showToast("Copied .htpasswd file")
                        } label: {
                            Label("Copy File", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .disabled(htpasswdEntries.isEmpty)
                    }
                    
                    TextEditor(text: .constant(htpasswdEntries.joined(separator: "\n")))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            computeHash()
        }
    }
    
    // MARK: - Logic
    private func computeHash() {
        guard !username.isEmpty, !password.isEmpty else {
            currentHash = ""
            return
        }
        
        switch algorithm {
        case .sha1:
            let digest = Insecure.SHA1.hash(data: Data(password.utf8))
            let b64 = Data(digest).base64EncodedString()
            currentHash = "\(username):{SHA}\(b64)"
            
        case .apr1:
            // Apache APR1 MD5 format
            let salt = randomSalt(length: 8)
            let raw = "\(password)$apr1$\(salt)"
            let digest = Insecure.MD5.hash(data: Data(raw.utf8))
            let hex = digest.map { String(format: "%02x", $0) }.joined()
            let sub = String(hex.prefix(22))
            currentHash = "\(username):$apr1$\(salt)$\(sub)"
            
        case .plaintext:
            currentHash = "\(username):\(password)"
        }
    }
    
    private func randomSalt(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    
    private func generateRandomPassword() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<14).map { _ in chars.randomElement()! })
    }
}
