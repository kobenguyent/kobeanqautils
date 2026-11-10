import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            if appState.isLoading && appState.estimatedProgress < 1.0 {
                ProgressView(value: appState.estimatedProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(height: 2)
                    .tint(.blue)
            }
            
            WebViewContainer(appState: appState)
        }
        .frame(minWidth: 900, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { appState.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!appState.canGoBack)
                .help("Back (⌘[)")
                
                Button(action: { appState.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!appState.canGoForward)
                .help("Forward (⌘])")
                
                Button(action: { appState.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload (⌘R)")
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Picker("Environment", selection: $appState.environment) {
                    ForEach(AppEnvironment.allCases) { env in
                        Text(env.rawValue).tag(env)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appState.environment) { _ in
                    appState.loadCurrentEnvironment()
                }
                .help("Switch between Bundled production assets and local Vite dev server")
                
                if appState.isDevServerReachable {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .help("Vite Dev Server is online at localhost:5173")
                }
                
                Menu {
                    Button("Zoom In (⌘+)") { appState.zoomIn() }
                    Button("Zoom Out (⌘-)") { appState.zoomOut() }
                    Button("Actual Size (⌘0)") { appState.resetZoom() }
                    Divider()
                    Button("Open in Default Browser") {
                        if let url = appState.currentURL {
                            NSWorkspace.shared.open(url)
                        } else {
                            NSWorkspace.shared.open(appState.environment.url)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
