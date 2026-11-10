import SwiftUI

@main
struct KobeanQAUtilsApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .navigationTitle(appState.pageTitle)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            AppCommands(appState: appState)
        }
    }
}
