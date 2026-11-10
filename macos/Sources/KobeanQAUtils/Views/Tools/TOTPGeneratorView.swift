import SwiftUI
import CryptoKit
import Combine

struct TOTPGeneratorView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var secretKey: String = "JBSWY3DPEHPK3PXP"
    @State private var digits: Int = 6
    @State private var period: Int = 30
    
    @State private var currentCode: String = "------"
    @State private var secondsRemaining: Int = 30
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .totp) {
                    secretKey = "JBSWY3DPEHPK3PXP"
                    calculateTOTP()
                }
                
                // Secret Key Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Base32 Secret Key")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("e.g. JBSWY3DPEHPK3PXP", text: $secretKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: secretKey) { _ in calculateTOTP() }
                        
                        Button("Demo Key") {
                            secretKey = "JBSWY3DPEHPK3PXP"
                            calculateTOTP()
                        }
                    }
                }
                
                // Live TOTP Display Box
                HStack(spacing: 24) {
                    // Code display
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current 2FA One-Time Passcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedCode)
                            .font(.system(size: 38, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .textSelection(.enabled)
                    }
                    
                    Spacer()
                    
                    // Circular countdown ring
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 5)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(secondsRemaining) / CGFloat(period))
                            .stroke(secondsRemaining <= 5 ? Color.red : Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 50, height: 50)
                            .animation(.linear(duration: 1.0), value: secondsRemaining)
                        
                        Text("\(secondsRemaining)s")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    
                    Button(action: {
                        appState.copyAndToast(currentCode, message: "Copied 2FA code!")
                    }) {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            }
            .padding(20)
        }
        .onAppear {
            calculateTOTP()
        }
        .onReceive(timer) { _ in
            let now = Int(Date().timeIntervalSince1970)
            secondsRemaining = period - (now % period)
            if secondsRemaining == period || currentCode == "------" {
                calculateTOTP()
            }
        }
    }
    
    private var formattedCode: String {
        if currentCode.count == 6 {
            let p1 = currentCode.prefix(3)
            let p2 = currentCode.suffix(3)
            return "\(p1) \(p2)"
        }
        return currentCode
    }
    
    private func calculateTOTP() {
        let cleanSecret = secretKey.replacingOccurrences(of: " ", with: "").uppercased()
        guard let keyData = base32Decode(cleanSecret), !keyData.isEmpty else {
            currentCode = "INVALID"
            return
        }
        
        let counter = UInt64(Date().timeIntervalSince1970) / UInt64(period)
        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: MemoryLayout<UInt64>.size)
        
        let symmetricKey = SymmetricKey(data: keyData)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: symmetricKey)
        let hmacBytes = Array(hmac)
        
        guard let lastByte = hmacBytes.last else { return }
        let offset = Int(lastByte & 0x0f)
        let truncatedHash = (UInt32(hmacBytes[offset] & 0x7f) << 24)
            | (UInt32(hmacBytes[offset + 1]) << 16)
            | (UInt32(hmacBytes[offset + 2]) << 8)
            | (UInt32(hmacBytes[offset + 3]))
        
        let codeNum = truncatedHash % 1_000_000
        currentCode = String(format: "%06d", codeNum)
    }
    
    private func base32Decode(_ str: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = ""
        for char in str {
            guard let idx = alphabet.firstIndex(of: char) else { continue }
            let val = alphabet.distance(from: alphabet.startIndex, to: idx)
            let binary = String(val, radix: 2)
            bits += String(repeating: "0", count: 5 - binary.count) + binary
        }
        
        var bytes: [UInt8] = []
        for i in stride(from: 0, to: bits.count - 7, by: 8) {
            let start = bits.index(bits.startIndex, offsetBy: i)
            let end = bits.index(start, offsetBy: 8)
            let byteStr = String(bits[start..<end])
            if let byte = UInt8(byteStr, radix: 2) {
                bytes.append(byte)
            }
        }
        return Data(bytes)
    }
}
