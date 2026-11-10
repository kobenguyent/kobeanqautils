import SwiftUI
import AppKit

enum GuideTopic: String, CaseIterable, Identifiable {
    case mcpAgents = "AI Agents & MCP"
    case cicdPyramid = "CI/CD & Test Pyramid"
    case apiTypes = "API Protocols Guide"
    case aiPrompts = "QA Prompt Engineering"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .mcpAgents: return "cpu"
        case .cicdPyramid: return "arrow.triangle.merge"
        case .apiTypes: return "network"
        case .aiPrompts: return "sparkles"
        }
    }
}

struct ArchitectureGuidesView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedTopic: GuideTopic = .mcpAgents
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .architectureGuides, onReset: { selectedTopic = .mcpAgents })
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Topic Switcher Bar
            Picker("Topic", selection: $selectedTopic) {
                ForEach(GuideTopic.allCases) { topic in
                    Label(topic.rawValue, systemImage: topic.icon).tag(topic)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTopic {
                    case .mcpAgents:
                        mcpAgentsGuideView
                    case .cicdPyramid:
                        cicdPyramidGuideView
                    case .apiTypes:
                        apiProtocolsGuideView
                    case .aiPrompts:
                        qaPromptsGuideView
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - MCP & AI Agents Guide
    private var mcpAgentsGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Model Context Protocol (MCP) & AI Agents")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Open protocol created by Anthropic allowing AI models to safely connect with local file systems, databases, developer tools, and external services.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Architecture Diagram Card
            VStack(alignment: .leading, spacing: 12) {
                Label("MCP Architecture Triad", systemImage: "triangle.fill")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    archBlock(title: "1. MCP Host", subtitle: "Claude Desktop / Antigravity IDE", desc: "Coordinates LLM runtime, user security approvals, and connection life cycles.", color: .blue)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    archBlock(title: "2. MCP Client", subtitle: "Internal Protocol Layer", desc: "Maintains 1:1 client sessions with each discovered tool or server.", color: .purple)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    archBlock(title: "3. MCP Server", subtitle: "Database / Git / GitHub", desc: "Exposes Tools (executable actions), Resources (read data), and Prompts.", color: .green)
                }
            }
            
            // The Three Primitives
            VStack(alignment: .leading, spacing: 10) {
                Text("The Three MCP Primitives for QA Automation")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    primitiveRow(
                        symbol: "wrench.and.screwdriver.fill",
                        name: "Tools (Executable Functions)",
                        desc: "Enable LLMs to run terminal commands, execute Playwright scripts, trigger CI/CD builds, or create Jira tickets with strict JSON Schema validations.",
                        color: .blue
                    )
                    primitiveRow(
                        symbol: "doc.text.fill",
                        name: "Resources (Contextual Data)",
                        desc: "Read-only payloads such as application server logs, database schemas, test results XML, or OpenAPI documentation fed into the LLM context window.",
                        color: .green
                    )
                    primitiveRow(
                        symbol: "bubble.left.and.bubble.right.fill",
                        name: "Prompts (Reusable Workflows)",
                        desc: "Structured prompt templates pre-packaged with recommended parameters for generating test plans, analyzing crash dumps, and reviewing code diffs.",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - CI/CD & Test Pyramid
    private var cicdPyramidGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Continuous Integration & The Agile Test Pyramid")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Maintain high deployment velocity and stable builds by placing faster, isolated tests at the base and reserving slower end-to-end browser tests for key flows.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Visual Pyramid
            VStack(spacing: 8) {
                pyramidTier(title: "UI & End-to-End (10%)", subtitle: "Playwright / Cypress / Appium — Slowest, Highest Maintenance, User Centric", widthPercent: 0.45, color: .red)
                pyramidTier(title: "API & Integration Tests (20%)", subtitle: "REST / GraphQL / Contract Testing — Fast, Reliable Business Logic", widthPercent: 0.70, color: .orange)
                pyramidTier(title: "Unit Tests & Static Analysis (70%)", subtitle: "Vitest / Jest / Pytest / ESLint — Millisecond execution, High Code Coverage", widthPercent: 0.95, color: .green)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Pipeline Stages
            VStack(alignment: .leading, spacing: 10) {
                Text("Standard Production CI/CD Pipeline Flow")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    stagePill("1. Lint & Format", icon: "checkmark.circle")
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                    stagePill("2. Unit Tests", icon: "bolt.fill")
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                    stagePill("3. Build Artifact", icon: "shippingbox.fill")
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                    stagePill("4. E2E Matrix", icon: "laptopcomputer")
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                    stagePill("5. Deploy Staging", icon: "cloud.fill")
                }
            }
        }
    }
    
    // MARK: - API Protocols Guide
    private var apiProtocolsGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Architectural Styles Comparison")
                .font(.title3)
                .fontWeight(.bold)
            
            let apis: [(name: String, transport: String, payload: String, pros: String, testTools: String)] = [
                ("REST", "HTTP/1.1 or HTTP/2", "JSON, XML", "Universal, simple caching, stateless", "REST Client, Postman, cURL"),
                ("GraphQL", "HTTP (POST)", "JSON query/response", "Single endpoint, no over-fetching, strong schema", "GraphQL Playground, Apollo"),
                ("gRPC", "HTTP/2", "Protocol Buffers (Binary)", "Ultra-fast serialization, bidirectional streaming", "gRPC Client, BloomRPC, Evans"),
                ("WebSocket", "TCP / ws:// / wss://", "Text, Binary frame", "Full duplex real-time streaming, minimal header overhead", "WebSocket Client, wscat"),
                ("Webhooks", "HTTP (POST reverse)", "JSON payload", "Event-driven asynchronous push notifications", "Ngrok, Webhook.site"),
                ("SOAP", "HTTP, SMTP", "XML exclusively", "Strict WS-Security, ACID transactions, enterprise legacy", "SoapUI, ReadyAPI")
            ]
            
            VStack(spacing: 8) {
                ForEach(apis, id: \.name) { api in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(api.name)
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            Spacer()
                            Text(api.transport)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 16) {
                            matrixItem(label: "Payload Format", value: api.payload)
                            matrixItem(label: "Key Advantage", value: api.pros)
                            matrixItem(label: "QA Testing Tools", value: api.testTools)
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - QA Prompt Engineering Guide
    private var qaPromptsGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Production AI System Prompts for QA Automation")
                .font(.title3)
                .fontWeight(.bold)
            
            promptCard(
                title: "1. Edge-Case Scenario Generator",
                snippet: """
                You are a Senior Principal QA Automation Engineer.
                Analyze the following user story or API endpoint specification.
                Generate a comprehensive test matrix categorized into:
                1. Happy Path & Boundary Values
                2. Negative & Invalid Input Scenarios
                3. Concurrency, Race Conditions & Timeout Edge Cases
                4. Security (Injection, Auth Bypass, Rate Limits)
                """
            )
            
            promptCard(
                title: "2. Playwright TypeScript Test Refactorer",
                snippet: """
                You are a Playwright test automation specialist.
                Refactor the provided script to follow best practices:
                - Use user-facing locators (page.getByRole, page.getByLabel)
                - Avoid hardcoded timeouts; utilize auto-waiting assertions (expect(locator).toBeVisible())
                - Extract reusable Page Object Models (POM) with clean TypeScript interfaces
                - Implement robust network mocking for external third-party dependencies
                """
            )
            
            promptCard(
                title: "3. Flaky Test Root Cause Diagnostician",
                snippet: """
                You are an expert in debugging asynchronous test flakiness.
                Inspect the attached test log and failure stack trace.
                Identify the root cause among:
                1. Asynchronous race condition / missing await
                2. Animation / DOM element rendering delay
                3. Shared database test state pollution between parallel workers
                4. Network latency jitter
                Provide the minimal, surgical fix with code diff.
                """
            )
        }
    }
    
    // MARK: - UI Helpers
    @ViewBuilder
    private func archBlock(title: String, subtitle: String, desc: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption2)
                .fontWeight(.bold)
            Text(desc)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func primitiveRow(symbol: String, name: String, desc: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func pyramidTier(title: String, subtitle: String, widthPercent: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .scaleEffect(x: widthPercent, y: 1.0)
        .background(color)
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func stagePill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func promptCard(title: String, snippet: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    ClipboardHelper.copy(snippet)
                    appState.showToast("Prompt copied to clipboard")
                }) {
                    Label("Copy Prompt", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text(snippet)
                .font(.system(.caption, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
    }
}
