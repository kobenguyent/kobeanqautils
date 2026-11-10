import SwiftUI
import AppKit

struct JiraCommentView: View {
    @EnvironmentObject private var appState: AppState
    
    enum TemplateType: String, CaseIterable, Identifiable {
        case bugReport = "QA Bug Report"
        case testSignoff = "Release QA Sign-Off"
        case infoPanel = "Info Panel"
        case errorPanel = "Defect / Blocker Panel"
        var id: String { rawValue }
    }
    
    @State private var template: TemplateType = .bugReport
    @State private var title: String = "Crash on login when network times out"
    @State private var environment: String = "macOS Sequoia 15.1 / App Version 1.2.0"
    @State private var steps: String = "1. Launch KobeanQAUtils\n2. Open REST Client\n3. Disconnect WiFi\n4. Click Execute"
    @State private var expected: String = "Graceful network error banner displayed"
    @State private var actual: String = "App hangs without timeout feedback"
    @State private var commentOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .jiraComment)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Comment Template", selection: $template) {
                        ForEach(TemplateType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .frame(maxWidth: 240)
                    .onChange(of: template) { _ in generateComment() }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Defect / Ticket Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: title) { _ in generateComment() }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Test Environment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Environment", text: $environment)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: environment) { _ in generateComment() }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps to Reproduce")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextEditor(text: $steps)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 70)
                            .padding(4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .onChange(of: steps) { _ in generateComment() }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expected Behavior")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Expected", text: $expected)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: expected) { _ in generateComment() }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Actual Behavior")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Actual", text: $actual)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: actual) { _ in generateComment() }
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Formatted Jira Markup Header
                HStack {
                    Text("Generated Jira Markup")
                        .font(.headline)
                    Spacer()
                    
                    Button {
                        ClipboardHelper.copy(commentOutput)
                        appState.showToast("Copied Jira formatted comment")
                    } label: {
                        Label("Copy Markup", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Output Editor
                TextEditor(text: $commentOutput)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 240)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            generateComment()
        }
    }
    
    // MARK: - Generation
    private func generateComment() {
        switch template {
        case .bugReport:
            commentOutput = """
{panel:title=🚨 QA Defect Report: \(title)|borderColor=#e11d48|bgColor=#fff1f2}
*Environment:* \(environment)
*Date:* \(Date().formatted(date: .abbreviated, time: .shortened))
{panel}

h3. Steps to Reproduce
\(steps)

h3. Results Comparison
|| Result || Details ||
| *Expected* | \(expected) |
| *Actual* | \(actual) |

h3. Verification Checklist
* (/) Automated test suite executed
* (x) Regression verified on native macOS app
"""
        case .testSignoff:
            commentOutput = """
{panel:title=✅ QA Release Sign-Off: \(title)|borderColor=#10b981|bgColor=#ecfdf5}
*Status:* APPROVED FOR RELEASE
*QA Lead:* Kobean QA Automation Team
*Target Release:* \(environment)
{panel}

h3. Test Execution Summary
|| Test Scope || Executed || Passed || Failed ||
| Unit & Integration | 1,276 | 1,276 | 0 |
| Native macOS App | 29 Tools | 29 | 0 |
| Performance / Memory | < 30 MB RAM | PASSED | 0 |
"""
        case .infoPanel:
            commentOutput = """
{panel:title=ℹ️ Info Note: \(title)|borderColor=#3b82f6|bgColor=#eff6ff}
\(expected)
{panel}
"""
        case .errorPanel:
            commentOutput = """
{panel:title=⛔ Critical Blocker: \(title)|borderColor=#ef4444|bgColor=#fef2f2}
*Environment:* \(environment)
*Impact:* \(actual)
{panel}
"""
        }
    }
}
