import SwiftUI

struct JWTDebuggerView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvYmUgVCIsImFkbWluIjp0cnVlLCJpYXQiOjE1MTYyMzkwMjIsImV4cCI6MjAwMDAwMDAwMH0.Xv06L4Hk39N-71c1Vn1j5V8_p7h-u4lV06K4Hk39N-4"
    
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
                        if let pasted = ClipboardHelper.paste() {
                            Button("Paste Token") { token = pasted }
                                .buttonStyle(.borderless)
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
            .padding(20)
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
