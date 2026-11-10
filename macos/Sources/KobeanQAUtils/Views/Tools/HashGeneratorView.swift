import SwiftUI
import CryptoKit

struct HashGeneratorView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var input: String = "The quick brown fox jumps over the lazy dog"
    @State private var uppercase: Bool = false
    @State private var enableHMAC: Bool = false
    @State private var hmacKey: String = "secret-key"
    
    struct HashResult: Identifiable {
        let id: String
        let name: String
        let bits: Int
        let value: String
    }
    
    private var results: [HashResult] {
        guard let data = input.data(using: .utf8) else { return [] }
        
        func format(_ bytes: [UInt8]) -> String {
            let str = bytes.map { String(format: "%02x", $0) }.joined()
            return uppercase ? str.uppercased() : str
        }
        
        var list: [HashResult] = []
        
        if enableHMAC {
            let key = SymmetricKey(data: hmacKey.data(using: .utf8) ?? Data())
            let hmac256 = HMAC<SHA256>.authenticationCode(for: data, using: key)
            list.append(HashResult(id: "hmac256", name: "HMAC-SHA256", bits: 256, value: format(Array(hmac256))))
            
            let hmac512 = HMAC<SHA512>.authenticationCode(for: data, using: key)
            list.append(HashResult(id: "hmac512", name: "HMAC-SHA512", bits: 512, value: format(Array(hmac512))))
        } else {
            // MD5
            let md5 = Insecure.MD5.hash(data: data)
            list.append(HashResult(id: "md5", name: "MD5", bits: 128, value: format(Array(md5))))
            
            // SHA-1
            let sha1 = Insecure.SHA1.hash(data: data)
            list.append(HashResult(id: "sha1", name: "SHA-1", bits: 160, value: format(Array(sha1))))
            
            // SHA-256
            let sha256 = SHA256.hash(data: data)
            list.append(HashResult(id: "sha256", name: "SHA-256", bits: 256, value: format(Array(sha256))))
            
            // SHA-384
            let sha384 = SHA384.hash(data: data)
            list.append(HashResult(id: "sha384", name: "SHA-384", bits: 384, value: format(Array(sha384))))
            
            // SHA-512
            let sha512 = SHA512.hash(data: data)
            list.append(HashResult(id: "sha512", name: "SHA-512", bits: 512, value: format(Array(sha512))))
        }
        
        return list
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .hashGen) {
                    input = ""
                }
                
                // Controls
                HStack(spacing: 20) {
                    Toggle("Uppercase Hex", isOn: $uppercase)
                    Toggle("HMAC Mode", isOn: $enableHMAC)
                    
                    if enableHMAC {
                        TextField("HMAC Secret Key", text: $hmacKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                    }
                    
                    Spacer()
                }
                
                // Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Text")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $input)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 90)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
                
                // Hash Output List
                VStack(alignment: .leading, spacing: 10) {
                    Text("Computed Hashes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ForEach(results) { res in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(res.name)
                                    .fontWeight(.semibold)
                                    .font(.subheadline)
                                Text("(\(res.bits) bits)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    appState.copyAndToast(res.value, message: "Copied \(res.name)!")
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            Text(res.value.isEmpty ? "—" : res.value)
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.04))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(20)
        }
    }
}
