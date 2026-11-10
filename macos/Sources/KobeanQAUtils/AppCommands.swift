import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var appState: AppState
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Reload Page") {
                appState.reload()
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Force Reload") {
                appState.reload()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
        
        CommandMenu("Navigation") {
            Button("Back") {
                appState.goBack()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!appState.canGoBack)
            
            Button("Forward") {
                appState.goForward()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!appState.canGoForward)
            
            Divider()
            
            Button("Toggle Dev / Bundled Mode") {
                appState.toggleEnvironment()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        
        CommandGroup(after: .toolbar) {
            Button("Zoom In") {
                appState.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                appState.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Actual Size") {
                appState.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)
        }
        
        CommandGroup(replacing: .help) {
            Button("KobeanQAUtils GitHub") {
                if let url = URL(string: "https://github.com/kobenguyent/kobeanqautils") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("Documentation") {
                if let url = URL(string: "https://github.com/kobenguyent/kobeanqautils#readme") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("Report Issue") {
                if let url = URL(string: "https://github.com/kobenguyent/kobeanqautils/issues") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
