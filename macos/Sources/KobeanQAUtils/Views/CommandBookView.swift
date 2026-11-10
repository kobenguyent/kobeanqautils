import SwiftUI
import AppKit

struct CommandItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let description: String
    let command: String
}

struct CommandBookView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedCategory: String = "All"
    @State private var searchFilter: String = ""
    
    private let categories = ["All", "Git", "macOS & System", "Docker", "Playwright", "CodeceptJS"]
    
    private let commands: [CommandItem] = [
        // macOS
        CommandItem(category: "macOS & System", title: "Clear Gatekeeper Quarantine", description: "Allows unsigned or ad-hoc signed apps to run without Gatekeeper blocking", command: "xattr -cr /Applications/KobeanQAUtils.app"),
        CommandItem(category: "macOS & System", title: "Verify App Code Signature", description: "Check code signing identity, entitlements and AMFI status", command: "codesign --verify --deep --strict --verbose=2 /Applications/KobeanQAUtils.app"),
        CommandItem(category: "macOS & System", title: "Find Process on Port", description: "Identify which process PID is listening on a given port (e.g. 5173)", command: "lsof -nP -iTCP:5173 -sTCP:LISTEN"),
        CommandItem(category: "macOS & System", title: "Flush DNS Cache", description: "Reset system DNS cache on macOS Sequoia / Sonoma", command: "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"),
        
        // Git
        CommandItem(category: "Git", title: "Undo Last Commit (Keep Changes)", description: "Soft reset to HEAD~1 leaving all file edits staged", command: "git reset --soft HEAD~1"),
        CommandItem(category: "Git", title: "Interactive Rebase Last N Commits", description: "Squash, edit or reorder the last 5 commits", command: "git rebase -i HEAD~5"),
        CommandItem(category: "Git", title: "Prune Deleted Remote Branches", description: "Clean up local tracking references for deleted remote branches", command: "git fetch --prune origin"),
        CommandItem(category: "Git", title: "Discard All Local Changes", description: "Hard reset working directory and clean untracked files", command: "git reset --hard HEAD && git clean -fd"),
        CommandItem(category: "Git", title: "Search Commit History by Message", description: "Find specific commits by keyword across all branches", command: "git log --all --grep=\"keyword\" --oneline"),
        
        // Docker
        CommandItem(category: "Docker", title: "Stop All Running Containers", description: "Gracefully stop every active container", command: "docker stop $(docker ps -q)"),
        CommandItem(category: "Docker", title: "Remove Dangling Images & Volumes", description: "Free up disk space by purging unused docker assets", command: "docker system prune -a --volumes -f"),
        CommandItem(category: "Docker", title: "Live Container Resource Usage", description: "Monitor CPU, memory and I/O of all running containers", command: "docker stats"),
        CommandItem(category: "Docker", title: "Interactive Shell Inside Container", description: "Open bash shell inside running container", command: "docker exec -it <container_id> /bin/bash"),
        
        // Playwright
        CommandItem(category: "Playwright", title: "Codegen Test Recorder", description: "Launch browser and record user clicks directly into test script", command: "npx playwright codegen https://example.com"),
        CommandItem(category: "Playwright", title: "Run Tests with Playwright Inspector", description: "Step through test execution step-by-step with live debugger", command: "npx playwright test --debug"),
        CommandItem(category: "Playwright", title: "Open HTML Test Report", description: "View interactive trace and video report from last run", command: "npx playwright show-report"),
        CommandItem(category: "Playwright", title: "Inspect Trace Viewer", description: "Open detailed step-by-step DOM snapshots and network logs", command: "npx playwright show-trace trace.zip"),
        
        // CodeceptJS
        CommandItem(category: "CodeceptJS", title: "Run Tests with Step Logging", description: "Print every step as it executes", command: "npx codeceptjs run --steps"),
        CommandItem(category: "CodeceptJS", title: "Run Specific Test Scenario", description: "Filter by test grep tag", command: "npx codeceptjs run --grep \"@smoke\"")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .commandBook)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Search & Category Filters
            HStack(spacing: 12) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { c in
                        Text(c).tag(c)
                    }
                }
                .frame(maxWidth: 180)
                
                TextField("Search commands by title, command, or keyword...", text: $searchFilter)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 24)
            
            // Commands List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredCommands) { item in
                        commandCard(item)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var filteredCommands: [CommandItem] {
        commands.filter { item in
            let matchesCat = selectedCategory == "All" || item.category == selectedCategory
            if !matchesCat { return false }
            if searchFilter.isEmpty { return true }
            let q = searchFilter.lowercased()
            return item.title.lowercased().contains(q) ||
                   item.description.lowercased().contains(q) ||
                   item.command.lowercased().contains(q)
        }
    }
    
    private func commandCard(_ item: CommandItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                
                Spacer()
                
                Text(item.category)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(4)
            }
            
            Text(item.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(item.command)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .textSelection(.enabled)
                
                Spacer()
                
                Button {
                    ClipboardHelper.copy(item.command)
                    appState.showToast("Copied command")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}
