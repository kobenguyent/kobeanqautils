import SwiftUI
import AppKit

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About KobeanQAUtils") {
                if let icon = AppDelegate.loadBrandIcon() {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationIcon: icon,
                        .version: "1.2.0"
                    ])
                } else {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
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
