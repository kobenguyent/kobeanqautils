import SwiftUI

struct JWTDebuggerView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var token: String = ""
    
    struct DecodedJWT {
        var headerJSON: String = ""
        var payloadJSON: String = ""
        var signature: String = ""
        var isExpired: Bool? = nil
        var expiryDate: Date? = nil
        var issuedAtDate: Date? = nil
        var claims: [(key: String, value: String)] = []
        var error: String? = nil
    }
    
    private var decoded: DecodedJWT {
        var res = DecodedJWT()
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return res }
        
        let parts = trimmed.components(separatedBy: ".")
        if parts.count != 3 {
            res.error = "Invalid JWT structure: Expected 3 parts separated by dots (Header.Payload.Signature), but found \(parts.count)."
            return res
        }
        
        func decodeBase64URL(_ base64Url: String) -> (json: String, dict: [String: Any])? {
            var str = base64Url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            let mod4 = str.count % 4
            if mod4 > 0 { str += String(repeating: "=", count: 4 - mod4) }
            guard let data = Data(base64Encoded: str) else { return nil }
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return (String(data: data, encoding: .utf8) ?? "", [:])
            }
            if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
               let prettyStr = String(data: prettyData, encoding: .utf8) {
                return (prettyStr, jsonObject)
            }
            return (String(data: data, encoding: .utf8) ?? "", jsonObject)
        }
        
        guard let header = decodeBase64URL(parts[0]) else {
            res.error = "Unable to decode JWT Header."
            return res
        }
        res.headerJSON = header.json
        
        guard let payload = decodeBase64URL(parts[1]) else {
            res.error = "Unable to decode JWT Payload."
            return res
        }
        res.payloadJSON = payload.json
        res.signature = parts[2]
        
        // Extract claims
        for (k, v) in payload.dict.sorted(by: { $0.key < $1.key }) {
            res.claims.append((k, "\(v)"))
        }
        
        if let exp = payload.dict["exp"] as? Double {
            let expDate = Date(timeIntervalSince1970: exp)
            res.expiryDate = expDate
            res.isExpired = expDate < Date()
        }
        
        if let iat = payload.dict["iat"] as? Double {
            res.issuedAtDate = Date(timeIntervalSince1970: iat)
        }
        
        return res
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .jwtDebugger) {
                    token = ""
                }
                
                // Input Token
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Encoded JWT Token")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: loadDemoToken) {
                            Label("Load Demo Token", systemImage: "sparkles")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        if let pasted = ClipboardHelper.paste() {
                            Button(action: { token = pasted }) {
                                Label("Paste Token", systemImage: "doc.on.clipboard")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        if !token.isEmpty {
                            Button(action: { token = "" }) {
                                Label("Clear", systemImage: "xmark.circle")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    TextEditor(text: $token)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
                
                if let err = decoded.error {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Status banner if expiry detected
                if let isExpired = decoded.isExpired, let expDate = decoded.expiryDate {
                    HStack(spacing: 12) {
                        Image(systemName: isExpired ? "xmark.shield.fill" : "checkmark.shield.fill")
                            .foregroundColor(isExpired ? .red : .green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isExpired ? "Token Expired" : "Token Active")
                                .fontWeight(.bold)
                                .foregroundColor(isExpired ? .red : .green)
                            
                            Text("Expires at: \(expDate.formatted(date: .abbreviated, time: .standard)) (\(relativeTime(from: expDate)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(isExpired ? Color.red.opacity(0.08) : Color.green.opacity(0.08))
                    .cornerRadius(8)
                }
                
                if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "key.horizontal")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No JWT Token Entered")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Paste a JSON Web Token above or click 'Load Demo Token' to inspect headers, payload claims, and verify expiry.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 340)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    // Decoded columns
                    HStack(alignment: .top, spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Header (Algorithm & Type)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Spacer()
                                Button("Copy") { appState.copyAndToast(decoded.headerJSON) }
                                    .buttonStyle(.borderless)
                                    .disabled(decoded.headerJSON.isEmpty)
                            }
                            
                            TextEditor(text: .constant(decoded.headerJSON))
                                .font(.system(.callout, design: .monospaced))
                                .frame(minHeight: 130)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Payload
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Payload (Data & Claims)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                Spacer()
                                Button("Copy") { appState.copyAndToast(decoded.payloadJSON) }
                                    .buttonStyle(.borderless)
                                    .disabled(decoded.payloadJSON.isEmpty)
                            }
                            
                            TextEditor(text: .constant(decoded.payloadJSON))
                                .font(.system(.callout, design: .monospaced))
                                .frame(minHeight: 130)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                        }
                    }
                    
                    // Signature
                    if !decoded.signature.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Signature")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(decoded.signature)
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Dynamic Demo Token Generator (Constructed at runtime, zero static secrets)
    private func loadDemoToken() {
        let headerDict: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
        ]
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + 86400 // Active for 24 hours
        let payloadDict: [String: Any] = [
            "sub": "qa_tester_9918",
            "name": "Kobean QA Tester",
            "role": "QA Automation Lead",
            "admin": true,
            "iat": now,
            "exp": exp
        ]
        
        func base64UrlEncode(_ dict: [String: Any]) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else {
                return ""
            }
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        
        let headerB64 = base64UrlEncode(headerDict)
        let payloadB64 = base64UrlEncode(payloadDict)
        let dummySignature = "mock_hmac_signature_for_qa_testing_only"
        
        token = "\(headerB64).\(payloadB64).\(dummySignature)"
        appState.showToast("Loaded dynamic demonstration token")
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
