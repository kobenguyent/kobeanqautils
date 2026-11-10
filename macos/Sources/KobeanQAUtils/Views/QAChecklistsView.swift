import SwiftUI
import AppKit

struct ChecklistItem: Identifiable, Hashable {
    let id: String
    let category: String
    let title: String
    let detail: String
    var isCompleted: Bool = false
}

struct QAChecklistsView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var activeTab: ChecklistDomain = .web
    @State private var webItems: [ChecklistItem] = []
    @State private var apiItems: [ChecklistItem] = []
    @State private var mobileItems: [ChecklistItem] = []
    @State private var filterMode: FilterMode = .all
    @State private var searchText: String = ""
    
    enum ChecklistDomain: String, CaseIterable, Identifiable {
        case web = "Web Application"
        case api = "REST / GraphQL API"
        case mobile = "iOS / Android Mobile"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .web: return "globe"
            case .api: return "network"
            case .mobile: return "iphone"
            }
        }
    }
    
    enum FilterMode: String, CaseIterable {
        case all = "All Items"
        case pending = "Pending"
        case completed = "Completed"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .qaChecklists, onReset: resetChecklists)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Domain Picker & Stats Bar
            VStack(spacing: 12) {
                HStack {
                    Picker("Domain", selection: $activeTab) {
                        ForEach(ChecklistDomain.allCases) { domain in
                            Label(domain.rawValue, systemImage: domain.icon).tag(domain)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 450)
                    
                    Spacer()
                    
                    Button(action: exportMarkdown) {
                        Label("Export Markdown", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Progress Bar & Filters
                HStack(spacing: 14) {
                    // Progress metric
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Completion: \(currentCompletedCount) of \(currentItems.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%.0f%%", currentProgress * 100))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(currentProgress == 1.0 ? .green : .accentColor)
                        }
                        ProgressView(value: currentProgress)
                            .tint(currentProgress == 1.0 ? .green : .accentColor)
                    }
                    .frame(width: 250)
                    
                    Divider().frame(height: 24)
                    
                    // Search box
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Filter items...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    
                    Picker("Show", selection: $filterMode) {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    
                    Menu {
                        Button("Mark All Completed") { markAll(true) }
                        Button("Clear All Checks") { markAll(false) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 30)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Checklist Items Grouped by Category
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    let grouped = Dictionary(grouping: filteredItems, by: { $0.category })
                    
                    ForEach(grouped.keys.sorted(), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            
                            VStack(spacing: 6) {
                                ForEach(grouped[category] ?? []) { item in
                                    HStack(alignment: .top, spacing: 10) {
                                        Button(action: {
                                            toggleItem(item)
                                        }) {
                                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                                .foregroundColor(item.isCompleted ? .green : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .strikethrough(item.isCompleted, color: .secondary)
                                                .foregroundColor(item.isCompleted ? .secondary : .primary)
                                            
                                            Text(item.detail)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if webItems.isEmpty {
                initDefaultItems()
            }
        }
    }
    
    // MARK: - Filtered List
    private var currentItems: [ChecklistItem] {
        switch activeTab {
        case .web: return webItems
        case .api: return apiItems
        case .mobile: return mobileItems
        }
    }
    
    private var currentCompletedCount: Int {
        currentItems.filter { $0.isCompleted }.count
    }
    
    private var currentProgress: Double {
        guard !currentItems.isEmpty else { return 0 }
        return Double(currentCompletedCount) / Double(currentItems.count)
    }
    
    private var filteredItems: [ChecklistItem] {
        currentItems.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.detail.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter: Bool = {
                switch filterMode {
                case .all: return true
                case .pending: return !item.isCompleted
                case .completed: return item.isCompleted
                }
            }()
            
            return matchesSearch && matchesFilter
        }
    }
    
    // MARK: - Actions
    private func toggleItem(_ target: ChecklistItem) {
        switch activeTab {
        case .web:
            if let idx = webItems.firstIndex(where: { $0.id == target.id }) {
                webItems[idx].isCompleted.toggle()
            }
        case .api:
            if let idx = apiItems.firstIndex(where: { $0.id == target.id }) {
                apiItems[idx].isCompleted.toggle()
            }
        case .mobile:
            if let idx = mobileItems.firstIndex(where: { $0.id == target.id }) {
                mobileItems[idx].isCompleted.toggle()
            }
        }
    }
    
    private func markAll(_ completed: Bool) {
        switch activeTab {
        case .web:
            webItems = webItems.map { var c = $0; c.isCompleted = completed; return c }
        case .api:
            apiItems = apiItems.map { var c = $0; c.isCompleted = completed; return c }
        case .mobile:
            mobileItems = mobileItems.map { var c = $0; c.isCompleted = completed; return c }
        }
    }
    
    private func exportMarkdown() {
        var md = "# QA Checklist Report — \(activeTab.rawValue)\n"
        md += "- **Status**: \(currentCompletedCount) of \(currentItems.count) completed (\(Int(currentProgress * 100))%)\n"
        md += "- **Date**: \(Date().description)\n\n"
        
        let grouped = Dictionary(grouping: currentItems, by: { $0.category })
        for cat in grouped.keys.sorted() {
            md += "### \(cat)\n"
            for item in grouped[cat] ?? [] {
                let check = item.isCompleted ? "[x]" : "[ ]"
                md += "- \(check) **\(item.title)**: \(item.detail)\n"
            }
            md += "\n"
        }
        
        ClipboardHelper.copy(md)
        appState.showToast("Checklist report copied to clipboard")
    }
    
    private func resetChecklists() {
        initDefaultItems()
    }
    
    private func initDefaultItems() {
        // Web Items
        webItems = [
            ChecklistItem(id: "w1", category: "🎨 UI & Responsiveness", title: "Cross-Device Layouts", detail: "Verify page render on Desktop (1920x1080), Tablet (768x1024), and Mobile (375x812)."),
            ChecklistItem(id: "w2", category: "🎨 UI & Responsiveness", title: "Dark & Light Mode", detail: "Ensure contrast, icons, and text readability switch seamlessly."),
            ChecklistItem(id: "w3", category: "🎨 UI & Responsiveness", title: "Typography & Overflow", detail: "Check long German/i18n strings do not break card boundaries or truncate awkwardly."),
            ChecklistItem(id: "w4", category: "🧪 Form Validation", title: "Required Field Indicators", detail: "Asterisks and accessible aria-required attributes present."),
            ChecklistItem(id: "w5", category: "🧪 Form Validation", title: "Boundary Value Testing", detail: "Test 0, 1, max-1, max, max+1 character lengths for input inputs."),
            ChecklistItem(id: "w6", category: "🧪 Form Validation", title: "SQL & XSS Injection Protection", detail: "Inject <script>alert(1)</script> and ' OR '1'='1 to verify sanitization."),
            ChecklistItem(id: "w7", category: "♿ Accessibility (WCAG 2.1)", title: "Keyboard Navigation", detail: "Full Tab / Shift+Tab tab order with visible active focus rings."),
            ChecklistItem(id: "w8", category: "♿ Accessibility (WCAG 2.1)", title: "Color Contrast Ratio", detail: "Meet minimum 4.5:1 for normal text and 3:1 for large text."),
            ChecklistItem(id: "w9", category: "♿ Accessibility (WCAG 2.1)", title: "Screen Reader Alt Text", detail: "Every functional <img> has descriptive alt tags; decorative icons have aria-hidden."),
            ChecklistItem(id: "w10", category: "🔒 Security & Sessions", title: "CSRF & Cookie Flags", detail: "Confirm SameSite=Strict and HttpOnly flags on session tokens."),
            ChecklistItem(id: "w11", category: "🔒 Security & Sessions", title: "Session Inactivity Timeout", detail: "Verify auto-logout triggers after 15–30 minutes of idle time.")
        ]
        
        // API Items
        apiItems = [
            ChecklistItem(id: "a1", category: "🌐 HTTP Methods & Routing", title: "RESTful Method Idempotency", detail: "GET, PUT, DELETE must be idempotent; POST creates new resource."),
            ChecklistItem(id: "a2", category: "🌐 HTTP Methods & Routing", title: "Status Code Standards", detail: "Verify 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found)."),
            ChecklistItem(id: "a3", category: "🛡️ Authentication & Authorization", title: "Expired Bearer Token", detail: "Expect 401 Unauthorized with token_expired code."),
            ChecklistItem(id: "a4", category: "🛡️ Authentication & Authorization", title: "Role-Based Access (RBAC)", detail: "Regular user cannot call admin management routes (expect 403 Forbidden)."),
            ChecklistItem(id: "a5", category: "⚡ Performance & Resilience", title: "Rate Limiting Thresholds", detail: "Fire 100 requests in 5s; verify 429 Too Many Requests response with Retry-After header."),
            ChecklistItem(id: "a6", category: "⚡ Performance & Resilience", title: "Payload Compression", detail: "Verify gzip or Brotli encoding supported on responses > 1KB.")
        ]
        
        // Mobile Items
        mobileItems = [
            ChecklistItem(id: "m1", category: "📱 Device Lifecycle", title: "App Launch & Cold Start", detail: "Verify splash screen finishes in < 2 seconds without flickering."),
            ChecklistItem(id: "m2", category: "📱 Device Lifecycle", title: "Background & Foreground Resume", detail: "Ensure app state, draft forms, and scroll position persist after multitasking."),
            ChecklistItem(id: "m3", category: "📶 Network Transitions", title: "Wi-Fi to Cellular Handoff", detail: "Seamless streaming / data fetch during connection switch."),
            ChecklistItem(id: "m4", category: "📶 Network Transitions", title: "Airplane / Offline Mode", detail: "Meaningful offline banner, retry buttons, and cached read-only access."),
            ChecklistItem(id: "m5", category: "🔋 Thermal & Battery", title: "Background CPU Throttling", detail: "No aggressive CPU polling or wake locks draining battery while app in background.")
        ]
    }
}
