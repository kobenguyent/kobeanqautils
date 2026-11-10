import SwiftUI
import AppKit

struct GitHubPRScriptView: View {
    @EnvironmentObject private var appState: AppState
    
    enum BranchPrefix: String, CaseIterable, Identifiable {
        case feat = "feat/"
        case fix = "fix/"
        case test = "test/"
        case refactor = "refactor/"
        case chore = "chore/"
        var id: String { rawValue }
    }
    
    @State private var branchPrefix: BranchPrefix = .feat
    @State private var branchSlug: String = "native-mac-tools-migration"
    @State private var prTitle: String = "feat(mac): migrate QA tools to pure native SwiftUI suite"
    @State private var prSummary: String = "Migrated web tools into native Swift engines with zero webview overhead."
    @State private var issueNumber: String = "42"
    @State private var reviewers: String = "kobenguyent"
    @State private var labels: String = "macos, native, quality-assurance"
    @State private var isDraft: Bool = false
    @State private var generatedScript: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .githubPrGen)
                
                // Form Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Branch Prefix & Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 6) {
                                Picker("", selection: $branchPrefix) {
                                    ForEach(BranchPrefix.allCases) { p in
                                        Text(p.rawValue).tag(p)
                                    }
                                }
                                .frame(width: 100)
                                .onChange(of: branchPrefix) { _ in generateScript() }
                                
                                TextField("branch-slug", text: $branchSlug)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: branchSlug) { _ in generateScript() }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Issue # (optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("e.g. 128", text: $issueNumber)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: issueNumber) { _ in generateScript() }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pull Request Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("PR Title", text: $prTitle)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: prTitle) { _ in generateScript() }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Summary / Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("PR Summary", text: $prSummary)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: prSummary) { _ in generateScript() }
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reviewers (comma separated)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("reviewers", text: $reviewers)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: reviewers) { _ in generateScript() }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Labels (comma separated)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("labels", text: $labels)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: labels) { _ in generateScript() }
                        }
                        
                        Toggle("Draft PR", isOn: $isDraft)
                            .toggleStyle(.checkbox)
                            .padding(.top, 16)
                            .onChange(of: isDraft) { _ in generateScript() }
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Script Output Header
                HStack {
                    Text("Generated Bash Script")
                        .font(.headline)
                    Spacer()
                    
                    Button {
                        saveScript()
                    } label: {
                        Label("Save Script...", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        ClipboardHelper.copy(generatedScript)
                        appState.showToast("Copied GitHub PR script")
                    } label: {
                        Label("Copy Script", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Output Editor
                TextEditor(text: $generatedScript)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 280)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            generateScript()
        }
    }
    
    // MARK: - Script Builder
    private func generateScript() {
        let fullBranch = "\(branchPrefix.rawValue)\(branchSlug)"
        
        var bodyLines: [String] = []
        bodyLines.append("## Summary")
        bodyLines.append(prSummary.isEmpty ? "Automated PR created via KobeanQAUtils." : prSummary)
        bodyLines.append("")
        bodyLines.append("## Verification")
        bodyLines.append("- [x] Automated test suite passing")
        bodyLines.append("- [x] Local native macOS build verified")
        if !issueNumber.isEmpty {
            bodyLines.append("")
            bodyLines.append("Fixes #\(issueNumber)")
        }
        
        let prBody = bodyLines.joined(separator: "\\n")
        
        var ghArgs: [String] = [
            "--title \"\(prTitle)\"",
            "--body \"\(prBody)\""
        ]
        if !reviewers.isEmpty {
            ghArgs.append("--reviewer \"\(reviewers)\"")
        }
        if !labels.isEmpty {
            ghArgs.append("--label \"\(labels)\"")
        }
        if isDraft {
            ghArgs.append("--draft")
        }
        
        generatedScript = """
#!/usr/bin/env bash
set -e

# Branch & PR Details
BRANCH="\(fullBranch)"

echo "🚀 Preparing pull request for branch: ${BRANCH}"

# 1. Ensure working directory is clean or stage changes
git checkout -B "${BRANCH}"
git add -A

# 2. Commit with conventional message
git commit -m "\(prTitle)" || echo "No new changes to commit."

# 3. Push branch to remote
echo "📤 Pushing ${BRANCH} to origin..."
git push -u origin "${BRANCH}"

# 4. Create Pull Request using GitHub CLI (gh)
if command -v gh >/dev/null 2>&1; then
    echo "✨ Creating GitHub Pull Request..."
    gh pr create \\
        \(ghArgs.joined(separator: " \\\n        "))
else
    echo "⚠️  GitHub CLI (gh) not found. Visit GitHub web to complete PR creation."
fi
"""
    }
    
    private func saveScript() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "create_pr.sh"
        if panel.runModal() == .OK, let url = panel.url {
            try? generatedScript.write(to: url, atomically: true, encoding: .utf8)
            appState.showToast("Saved script to \(url.lastPathComponent)")
        }
    }
}
