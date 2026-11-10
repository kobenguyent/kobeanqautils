import SwiftUI

struct PasswordGeneratorView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var length: Double = 16
    @State private var useUppercase: Bool = true
    @State private var useLowercase: Bool = true
    @State private var useNumbers: Bool = true
    @State private var useSymbols: Bool = true
    @State private var excludeAmbiguous: Bool = false
    @State private var bulkCount: Double = 1
    
    @State private var generatedPasswords: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolHeaderView(tool: .passwordGen) {
                    length = 16
                    useUppercase = true
                    useLowercase = true
                    useNumbers = true
                    useSymbols = true
                    excludeAmbiguous = false
                    bulkCount = 1
                    generate()
                }
                
                // Config Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password Length: \(Int(length)) characters")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        Slider(value: $length, in: 6...64, step: 1)
                            .onChange(of: length) { _ in generate() }
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Uppercase (A-Z)", isOn: $useUppercase)
                            .onChange(of: useUppercase) { _ in generate() }
                        Toggle("Lowercase (a-z)", isOn: $useLowercase)
                            .onChange(of: useLowercase) { _ in generate() }
                        Toggle("Numbers (0-9)", isOn: $useNumbers)
                            .onChange(of: useNumbers) { _ in generate() }
                        Toggle("Symbols (!@#$)", isOn: $useSymbols)
                            .onChange(of: useSymbols) { _ in generate() }
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Exclude Ambiguous (0, O, 1, l, I)", isOn: $excludeAmbiguous)
                            .onChange(of: excludeAmbiguous) { _ in generate() }
                        
                        Spacer()
                        
                        HStack {
                            Text("Quantity: \(Int(bulkCount))")
                            Stepper("", value: $bulkCount, in: 1...20)
                                .onChange(of: bulkCount) { _ in generate() }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(10)
                
                // Strength calculation
                if let primary = generatedPasswords.first, !primary.isEmpty {
                    let score = evaluateStrength(primary)
                    HStack(spacing: 12) {
                        Text("Strength: \(score.label)")
                            .fontWeight(.bold)
                            .foregroundColor(score.color)
                        
                        ProgressView(value: score.fraction, total: 1.0)
                            .tint(score.color)
                            .frame(maxWidth: 200)
                        
                        Spacer()
                        
                        Button(action: generate) {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Generated Output List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generated Passwords")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if generatedPasswords.count > 1 {
                            Button("Copy All") {
                                appState.copyAndToast(generatedPasswords.joined(separator: "\n"))
                            }
                        }
                    }
                    
                    ForEach(generatedPasswords, id: \.self) { pwd in
                        HStack {
                            Text(pwd)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button(action: {
                                appState.copyAndToast(pwd)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("Copy to clipboard")
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            if generatedPasswords.isEmpty { generate() }
        }
    }
    
    private func generate() {
        var pool = ""
        if useUppercase { pool += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if useLowercase { pool += "abcdefghijklmnopqrstuvwxyz" }
        if useNumbers { pool += "0123456789" }
        if useSymbols { pool += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        
        if excludeAmbiguous {
            pool = pool.filter { !"0O1lI".contains($0) }
        }
        
        if pool.isEmpty {
            generatedPasswords = ["[Select at least one character type]"]
            return
        }
        
        let count = Int(bulkCount)
        let len = Int(length)
        var list: [String] = []
        
        for _ in 0..<count {
            var pwd = ""
            for _ in 0..<len {
                if let char = pool.randomElement() {
                    pwd.append(char)
                }
            }
            list.append(pwd)
        }
        generatedPasswords = list
    }
    
    private func evaluateStrength(_ pwd: String) -> (label: String, color: Color, fraction: Double) {
        var poolSize = 0
        if useUppercase { poolSize += 26 }
        if useLowercase { poolSize += 26 }
        if useNumbers { poolSize += 10 }
        if useSymbols { poolSize += 25 }
        if poolSize == 0 { poolSize = 1 }
        
        let entropy = Double(pwd.count) * (log2(Double(poolSize)))
        if entropy < 36 {
            return ("Weak", .red, 0.25)
        } else if entropy < 60 {
            return ("Fair", .orange, 0.5)
        } else if entropy < 85 {
            return ("Strong", .blue, 0.75)
        } else {
            return ("Very Strong", .green, 1.0)
        }
    }
}
