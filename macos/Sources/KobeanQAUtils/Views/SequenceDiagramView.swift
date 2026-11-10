import SwiftUI
import AppKit

struct SequenceDiagramView: View {
    @EnvironmentObject private var appState: AppState
    
    enum DiagramSourceFormat: String, CaseIterable, Identifiable {
        case playwright = "Playwright Test"
        case codecept = "CodeceptJS Test"
        case plainSteps = "Step Statements"
        var id: String { rawValue }
    }
    
    @State private var format: DiagramSourceFormat = .playwright
    @State private var sourceCode: String = """
test('User Checkout Flow', async ({ page, request }) => {
  await page.goto('https://shop.example.com');
  await page.click('#add-to-cart');
  await page.click('#checkout');
  await request.post('/api/checkout', { data: { cartId: '123' } });
  await expect(page.locator('.order-confirmed')).toBeVisible();
});
"""
    @State private var mermaidOutput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .sequenceDiagram)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Toolbar
            HStack(spacing: 16) {
                Picker("Parser", selection: $format) {
                    ForEach(DiagramSourceFormat.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .frame(maxWidth: 220)
                .onChange(of: format) { _ in generateDiagram() }
                
                Button("Sample") {
                    loadSample()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Clear") {
                    sourceCode = ""
                    mermaidOutput = ""
                }
                .buttonStyle(.borderless)
                
                Button {
                    ClipboardHelper.copy(mermaidOutput)
                    appState.showToast("Copied Mermaid sequence diagram")
                } label: {
                    Label("Copy Mermaid", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(mermaidOutput.isEmpty)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane Editors
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Left Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Test Script / Flow Input")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $sourceCode)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .onChange(of: sourceCode) { _ in generateDiagram() }
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Right Output
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mermaid Sequence Diagram Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $mermaidOutput)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            generateDiagram()
        }
    }
    
    // MARK: - Parser & Generator
    private func generateDiagram() {
        var lines: [String] = ["sequenceDiagram", "    autonumber", "    actor User", "    participant Browser", "    participant Backend"]
        
        let rawLines = sourceCode.components(separatedBy: "\n")
        var stepsCount = 0
        
        for line in rawLines {
            let l = line.trimmingCharacters(in: .whitespaces)
            if l.isEmpty || l.hasPrefix("//") || l.hasPrefix("/*") { continue }
            
            if l.contains("goto(") || l.contains("amOnPage(") {
                let url = extractArgument(l) ?? "Target URL"
                lines.append("    User->>Browser: Open page (\(url))")
                lines.append("    Browser->>Backend: GET \(url)")
                lines.append("    Backend-->>Browser: 200 OK HTML")
                stepsCount += 1
            } else if l.contains("click(") {
                let loc = extractArgument(l) ?? "element"
                lines.append("    User->>Browser: Click \(loc)")
                stepsCount += 1
            } else if l.contains("fill(") || l.contains("fillField(") {
                let arg = extractArgument(l) ?? "input"
                lines.append("    User->>Browser: Type into \(arg)")
                stepsCount += 1
            } else if l.contains("post(") || l.contains("sendPostRequest(") {
                let endpoint = extractArgument(l) ?? "/api"
                lines.append("    Browser->>Backend: POST \(endpoint)")
                lines.append("    Backend-->>Browser: 200 JSON Response")
                stepsCount += 1
            } else if l.contains("expect(") || l.contains("seeElement(") || l.contains("see(") {
                lines.append("    Browser-->>User: Verify element / assertion passed")
                stepsCount += 1
            } else if l.contains("->>") || l.contains("-->") {
                // Direct Mermaid or step line
                lines.append("    " + l)
                stepsCount += 1
            }
        }
        
        if stepsCount == 0 {
            lines.append("    User->>Browser: Perform test actions")
            lines.append("    Browser-->>User: Verify result")
        }
        
        mermaidOutput = lines.joined(separator: "\n")
    }
    
    private func extractArgument(_ line: String) -> String? {
        if let start = line.firstIndex(of: "'"), let end = line[line.index(after: start)...].firstIndex(of: "'") {
            return String(line[line.index(after: start)..<end])
        }
        if let start = line.firstIndex(of: "\""), let end = line[line.index(after: start)...].firstIndex(of: "\"") {
            return String(line[line.index(after: start)..<end])
        }
        return nil
    }
    
    private func loadSample() {
        sourceCode = """
test('User Checkout Flow', async ({ page, request }) => {
  await page.goto('https://shop.example.com');
  await page.click('#add-to-cart');
  await page.click('#checkout');
  await request.post('/api/checkout', { data: { cartId: '123' } });
  await expect(page.locator('.order-confirmed')).toBeVisible();
});
"""
        generateDiagram()
    }
}
