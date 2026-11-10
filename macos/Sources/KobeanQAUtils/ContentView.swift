import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            ZStack(alignment: .bottom) {
                detailContent
                    .frame(minWidth: 650, minHeight: 520)
                
                // Toast notification
                if let toast = appState.toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(toast)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThickMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .environmentObject(appState)
        .navigationTitle(appState.selectedTool.title)
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        List(selection: $appState.selectedTool) {
            // Header Branding
            HStack(spacing: 12) {
                if let brandImage = AppDelegate.loadBrandLogo() {
                    Image(nsImage: brandImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("KobeanQAUtils")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Native QA & Dev Suite")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            
            ForEach(ToolCategory.allCases) { category in
                let tools = appState.filteredTools(in: category)
                if !tools.isEmpty {
                    Section(header: Label(category.rawValue, systemImage: category.icon)) {
                        ForEach(tools) { tool in
                            NavigationLink(value: tool) {
                                Label {
                                    Text(tool.title)
                                        .font(.subheadline)
                                } icon: {
                                    Image(systemName: tool.icon)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $appState.searchText, placement: .sidebar, prompt: "Search tools (⌘F)...")
    }
    
    // MARK: - Detail View Router
    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedTool {
        case .base64:
            Base64ToolView()
        case .hashGen:
            HashGeneratorView()
        case .jwtDebugger:
            JWTDebuggerView()
        case .passwordGen:
            PasswordGeneratorView()
        case .uuidGen:
            UUIDGeneratorView()
        case .timestamp:
            TimestampConverterView()
        case .totp:
            TOTPGeneratorView()
        case .textAnalyzer:
            TextAnalyzerView()
        case .jsonFormatter:
            JSONFormatterView()
        case .restClient:
            RESTClientView()
        case .diffComparator:
            DiffComparatorView()
        case .qrCode:
            QRCodeToolView()
        case .sqlHelper:
            SQLHelperView()
        case .colorConverter:
            ColorConverterView()
        case .markdownConverter:
            MarkdownConverterView()
        case .encryptionTool:
            EncryptionToolView()
        case .htpasswdGen:
            HTPasswdGeneratorView()
        case .loremIpsum:
            LoremIpsumView()
        case .dummyData:
            DummyDataGeneratorView()
        case .websocketClient:
            WebSocketClientView()
        case .testFileGen:
            TestFileGeneratorView()
        case .playwrightConverter:
            PlaywrightConverterView()
        case .graphqlClient:
            GraphQLClientView()
        case .fileProcessor:
            FileProcessorView()
        case .jiraComment:
            JiraCommentView()
        case .workflowGen:
            WorkflowGeneratorView()
        case .sequenceDiagram:
            SequenceDiagramView()
        case .githubPrGen:
            GitHubPRScriptView()
        case .commandBook:
            CommandBookView()
        case .htmlRenderer:
            HtmlRendererView()
        case .grpcClient:
            GrpcClientView()
        case .promptEnhancer:
            PromptEnhancerView()
        case .jsonPromptBuilder:
            JsonPromptBuilderView()
        case .logCollector:
            LogCollectorView()
        case .kanbanBoard:
            KanbanBoardView()
        case .flashcards:
            FlashcardsView()
        case .jsonVisualizer:
            JsonVisualizerView()
        case .mediaConverter:
            MediaConverterView()
        case .collectionManager:
            CollectionManagerView()
        case .websiteScanner:
            WebsiteScannerView()
        case .fileComparator:
            FileComparatorView()
        case .testingCheatsheet:
            TestingCheatsheetView()
        case .localLlmGuide:
            LocalLLMGuideView()
        case .qaChecklists:
            QAChecklistsView()
        case .telecomProtocols:
            TelecomProtocolsView()
        case .istqbExam:
            ISTQBPracticeExamView()
        case .architectureGuides:
            ArchitectureGuidesView()
        }
    }
}
