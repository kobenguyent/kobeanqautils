import SwiftUI

struct UUIDGeneratorView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var uppercase: Bool = false
    @State private var includeHyphens: Bool = true
    @State private var count: Double = 5
    @State private var uuids: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeaderView(tool: .uuidGen) {
                    uppercase = false
                    includeHyphens = true
                    count = 5
                    generate()
                }
                
                // Controls
                HStack(spacing: 20) {
                    Toggle("Uppercase", isOn: $uppercase)
                        .onChange(of: uppercase) { _ in formatExisting() }
                    Toggle("Include Hyphens", isOn: $includeHyphens)
                        .onChange(of: includeHyphens) { _ in formatExisting() }
                    
                    HStack {
                        Text("Count: \(Int(count))")
                        Stepper("", value: $count, in: 1...50)
                            .onChange(of: count) { _ in generate() }
                    }
                    
                    Spacer()
                    
                    Button(action: generate) {
                        Label("Generate New", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(10)
                
                // Results
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generated UUIDs (\(uuids.count))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Copy All") {
                            appState.copyAndToast(uuids.joined(separator: "\n"), message: "Copied all \(uuids.count) UUIDs!")
                        }
                        .disabled(uuids.isEmpty)
                    }
                    
                    ForEach(uuids, id: \.self) { u in
                        HStack {
                            Text(u)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button(action: {
                                appState.copyAndToast(u)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
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
            if uuids.isEmpty { generate() }
        }
    }
    
    @State private var rawUUIDs: [UUID] = []
    
    private func generate() {
        let n = Int(count)
        rawUUIDs = (0..<n).map { _ in UUID() }
        formatExisting()
    }
    
    private func formatExisting() {
        uuids = rawUUIDs.map { uuid in
            var str = uuid.uuidString
            if !includeHyphens {
                str = str.replacingOccurrences(of: "-", with: "")
            }
            return uppercase ? str.uppercased() : str.lowercased()
        }
    }
}
