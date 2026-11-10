import SwiftUI
import AppKit

struct FrameworkCommand: Identifiable {
    let id = UUID()
    let command: String
    let description: String
    let category: String
}

struct FrameworkComparisonRow: Identifiable {
    let id = UUID()
    let name: String
    let language: String
    let speed: String
    let multiTab: String
    let shadowDom: String
    let mobileSupport: String
    let bestFor: String
}

struct TestingCheatsheetView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedTab: String = "Playwright"
    @State private var searchText: String = ""
    @State private var showComparisonMatrix: Bool = false
    
    let frameworks = ["Playwright", "CodeceptJS", "Cypress", "Pytest", "Jest/Vitest", "K6"]
    
    let commandsDict: [String: [FrameworkCommand]] = [
        "Playwright": [
            FrameworkCommand(command: "npx playwright test", description: "Run all test specs across configured browsers", category: "Execution"),
            FrameworkCommand(command: "npx playwright test --ui", description: "Launch interactive graphical test runner with time-travel", category: "Debugging"),
            FrameworkCommand(command: "npx playwright test --headed", description: "Run tests with visible browser window", category: "Execution"),
            FrameworkCommand(command: "npx playwright test --project=chromium", description: "Execute tests exclusively on Chromium/Chrome engine", category: "Execution"),
            FrameworkCommand(command: "npx playwright test --grep \"@smoke\"", description: "Filter and run tests tagged with @smoke", category: "Filtering"),
            FrameworkCommand(command: "npx playwright codegen https://example.com", description: "Generate test script by recording browser clicks and typing", category: "Generators"),
            FrameworkCommand(command: "npx playwright show-trace trace.zip", description: "Inspect full DOM snapshot, console logs, and network waterfall", category: "Debugging"),
            FrameworkCommand(command: "npx playwright test --workers=4", description: "Run test suites with 4 parallel worker processes", category: "Performance")
        ],
        "CodeceptJS": [
            FrameworkCommand(command: "npx codeceptjs run", description: "Run all CodeceptJS BDD end-to-end scenarios", category: "Execution"),
            FrameworkCommand(command: "npx codeceptjs run --steps", description: "Print step-by-step actor interactions in terminal", category: "Debugging"),
            FrameworkCommand(command: "npx codeceptjs run-workers 3", description: "Execute tests in parallel across 3 workers", category: "Performance"),
            FrameworkCommand(command: "npx codeceptjs run --grep \"@regression\"", description: "Run scenarios matching grep tag", category: "Filtering"),
            FrameworkCommand(command: "npx codeceptjs run --debug", description: "Enable verbose diagnostic logs and error screenshots", category: "Debugging"),
            FrameworkCommand(command: "npx codeceptjs g:feature", description: "Scaffold a new Gherkin feature and test definition", category: "Generators")
        ],
        "Cypress": [
            FrameworkCommand(command: "npx cypress open", description: "Open Cypress interactive desktop test runner", category: "Execution"),
            FrameworkCommand(command: "npx cypress run", description: "Run all Cypress specs headlessly in terminal", category: "Execution"),
            FrameworkCommand(command: "npx cypress run --spec \"cypress/e2e/login.cy.ts\"", description: "Execute a single targeted spec file", category: "Execution"),
            FrameworkCommand(command: "npx cypress run --browser chrome", description: "Run headless tests on Google Chrome", category: "Execution"),
            FrameworkCommand(command: "npx cypress run --record --key <dashboard-key>", description: "Record test artifacts to Cypress Cloud", category: "CI/CD")
        ],
        "Pytest": [
            FrameworkCommand(command: "pytest -v", description: "Run test suite with verbose output per test function", category: "Execution"),
            FrameworkCommand(command: "pytest -m smoke", description: "Run tests tagged with @pytest.mark.smoke", category: "Filtering"),
            FrameworkCommand(command: "pytest -n auto", description: "Distribute tests across CPU cores with pytest-xdist", category: "Performance"),
            FrameworkCommand(command: "pytest -k \"test_login or test_auth\"", description: "Run tests matching keyword expression", category: "Filtering"),
            FrameworkCommand(command: "pytest --cov=app --cov-report=html", description: "Generate line coverage report in HTML format", category: "Coverage"),
            FrameworkCommand(command: "pytest -s -x", description: "Show stdout print logs and halt on first failure", category: "Debugging")
        ],
        "Jest/Vitest": [
            FrameworkCommand(command: "npm test -- --watch", description: "Run tests in interactive watch mode on changed files", category: "Execution"),
            FrameworkCommand(command: "npx vitest run --coverage", description: "Execute tests once and output v8 code coverage", category: "Coverage"),
            FrameworkCommand(command: "npm test -- -u", description: "Update outdated inline or snapshot assertions", category: "Maintenance"),
            FrameworkCommand(command: "npm test -- --runInBand", description: "Run all tests serially in the same Node process", category: "Debugging")
        ],
        "K6": [
            FrameworkCommand(command: "k6 run script.js", description: "Run load test script with default virtual users", category: "Execution"),
            FrameworkCommand(command: "k6 run --vus 50 --duration 3m script.js", description: "Simulate 50 concurrent virtual users for 3 minutes", category: "Load Testing"),
            FrameworkCommand(command: "k6 cloud script.js", description: "Distribute load test across Grafana Cloud zones", category: "Cloud")
        ]
    ]
    
    let comparisons: [FrameworkComparisonRow] = [
        FrameworkComparisonRow(name: "Playwright", language: "TS, JS, Python, C#, Java", speed: "⚡ Ultra Fast", multiTab: "✅ Native (BrowserContext)", shadowDom: "✅ Auto-pierce", mobileSupport: "✅ Chrome/Safari Emulation", bestFor: "Modern web apps, multi-tab flows, API testing"),
        FrameworkComparisonRow(name: "CodeceptJS", language: "JavaScript, TypeScript", speed: "⚡ Fast", multiTab: "✅ Supported", shadowDom: "✅ Supported", mobileSupport: "✅ Appium / WebDriver", bestFor: "BDD, cross-engine abstraction (Playwright/Puppeteer/WebDriver)"),
        FrameworkComparisonRow(name: "Cypress", language: "JavaScript, TypeScript", speed: "⚡ Fast", multiTab: "⚠️ Limited (Single-origin)", shadowDom: "✅ With config", mobileSupport: "⚠️ Viewport only", bestFor: "Component testing, Single Page Apps"),
        FrameworkComparisonRow(name: "Selenium WebDriver", language: "Java, Python, C#, JS, Ruby", speed: "🐢 Moderate", multiTab: "✅ Supported", shadowDom: "⚠️ Manual locators", mobileSupport: "✅ Via Appium", bestFor: "Legacy enterprise suites, older browser matrix"),
        FrameworkComparisonRow(name: "Appium", language: "Java, Python, JS, C#", speed: "🐢 Moderate", multiTab: "N/A (Mobile)", shadowDom: "N/A", mobileSupport: "✅ Real iOS & Android native apps", bestFor: "Native & Hybrid iOS/Android mobile testing")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .testingCheatsheet, onReset: { searchText = ""; selectedTab = "Playwright" })
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Framework Selector Bar
            HStack(spacing: 12) {
                Picker("Framework", selection: $selectedTab) {
                    ForEach(frameworks, id: \.self) { fw in
                        Text(fw).tag(fw)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 550)
                
                Spacer()
                
                Button(action: { showComparisonMatrix.toggle() }) {
                    Label(showComparisonMatrix ? "Hide Matrix" : "Comparison Matrix", systemImage: "tablecells")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search commands or use-cases across all frameworks...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Comparison Matrix Section (Toggleable)
                    if showComparisonMatrix {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Framework Comparison Matrix", systemImage: "chart.bar.doc.horizontal")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(comparisons) { row in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(row.name)
                                                .font(.headline)
                                                .foregroundColor(.accentColor)
                                            Spacer()
                                            Text(row.speed)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(4)
                                        }
                                        
                                        HStack(spacing: 16) {
                                            matrixItem(label: "Languages", value: row.language)
                                            matrixItem(label: "Multi-tab", value: row.multiTab)
                                            matrixItem(label: "Shadow DOM", value: row.shadowDom)
                                            matrixItem(label: "Mobile", value: row.mobileSupport)
                                        }
                                        
                                        Text("Best for: \(row.bestFor)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Commands List
                    let currentCommands = activeFilteredCommands
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(selectedTab) CLI Commands")
                                .font(.headline)
                            Spacer()
                            Text("\(currentCommands.count) commands")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(currentCommands) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.category)
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                        
                                        Text(item.command)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.semibold)
                                            .textSelection(.enabled)
                                        
                                        Text(item.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: {
                                        ClipboardHelper.copy(item.command)
                                        appState.showToast("Copied: \(item.command)")
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("Copy command")
                                }
                                .padding(10)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var activeFilteredCommands: [FrameworkCommand] {
        let list = commandsDict[selectedTab] ?? []
        guard !searchText.isEmpty else { return list }
        return list.filter {
            $0.command.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @ViewBuilder
    private func matrixItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
        }
    }
}
