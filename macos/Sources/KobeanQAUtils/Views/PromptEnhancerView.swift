import SwiftUI
import AppKit

struct PromptEnhancerView: View {
    @EnvironmentObject private var appState: AppState
    
    enum TargetRole: String, CaseIterable, Identifiable {
        case qaEngineer = "Senior QA Automation Engineer"
        case securityAuditor = "Application Security Auditor"
        case backendArchitect = "Backend Systems Architect"
        case devopsSpecialist = "DevOps & CI/CD Specialist"
        var id: String { rawValue }
    }
    
    enum OutputStyle: String, CaseIterable, Identifiable {
        case structuredMarkdown = "Structured Markdown"
        case jsonOnly = "Strict JSON Only"
        case stepByStep = "Step-by-Step Chain of Thought"
        case conciseChecklist = "Actionable QA Checklist"
        var id: String { rawValue }
    }
    
    @State private var rawPrompt: String = "Write automated tests for user authentication and token refresh."
    @State private var role: TargetRole = .qaEngineer
    @State private var style: OutputStyle = .structuredMarkdown
    @State private var includeConstraints: Bool = true
    @State private var includeExamples: Bool = true
    @State private var enhancedOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .promptEnhancer)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Persona / Role")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $role) {
                                ForEach(TargetRole.allCases) { r in
                                    Text(r.rawValue).tag(r)
                                }
                            }
                            .onChange(of: role) { _ in enhance() }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Output Format")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $style) {
                                ForEach(OutputStyle.allCases) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .onChange(of: style) { _ in enhance() }
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Include Strict Constraints", isOn: $includeConstraints)
                            .toggleStyle(.checkbox)
                            .onChange(of: includeConstraints) { _ in enhance() }
                        
                        Toggle("Include Few-Shot Structure", isOn: $includeExamples)
                            .toggleStyle(.checkbox)
                            .onChange(of: includeExamples) { _ in enhance() }
                        
                        Spacer()
                        
                        Button {
                            enhance()
                        } label: {
                            Label("Enhance Prompt", systemImage: "sparkles")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Raw Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original Prompt / Instruction")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $rawPrompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                        .onChange(of: rawPrompt) { _ in enhance() }
                }
                
                // Enhanced Output
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Optimized System Prompt")
                            .font(.headline)
                        Spacer()
                        
                        Button {
                            ClipboardHelper.copy(enhancedOutput)
                            appState.showToast("Copied enhanced AI prompt")
                        } label: {
                            Label("Copy Prompt", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    TextEditor(text: $enhancedOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 260)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(24)
        }
        .onAppear {
            enhance()
        }
    }
    
    // MARK: - Engine
    private func enhance() {
        var sections: [String] = []
        
        sections.append("""
# ROLE
You are an expert \(role.rawValue) with deep domain authority in test automation, quality assurance, and software resilience.
""")
        
        sections.append("""
# TASK & CONTEXT
\(rawPrompt)
""")
        
        if includeConstraints {
            sections.append("""
# CONSTRAINTS & GUIDELINES
- Provide clear, production-grade solutions without omitting error handling.
- Adhere strictly to industry standards (e.g. ISTQB, RFC specifications).
- Highlight edge cases, boundary conditions, and potential security vulnerabilities.
- Avoid unnecessary conversational fluff; focus directly on technical execution.
""")
        }
        
        sections.append("""
# OUTPUT FORMAT
Format your entire response as \(style.rawValue). Ensure all code blocks specify syntax tags.
""")
        
        if includeExamples {
            sections.append("""
# VERIFICATION CHECKLIST
1. Verify happy path functionality.
2. Verify negative test scenarios and invalid input rejection.
3. Validate response timing, timeout recovery, and logging.
""")
        }
        
        enhancedOutput = sections.joined(separator: "\n\n")
    }
}
