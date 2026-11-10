import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupBrandIcon()
    }
    
    private func setupBrandIcon() {
        if let iconImage = Self.loadBrandIcon() {
            NSApplication.shared.applicationIconImage = iconImage
        }
    }
    
    static func loadBrandIcon() -> NSImage? {
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return nil
    }
    
    static func loadBrandLogo() -> NSImage? {
        if let img = NSImage(named: "AppLogo") {
            return img
        }
        if let url = Bundle.main.url(forResource: "AppLogo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return loadBrandIcon()
    }
}

@main
struct KobeanQAUtilsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            AppCommands()
        }
    }
}
