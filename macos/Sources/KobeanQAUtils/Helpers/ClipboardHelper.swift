import AppKit

enum ClipboardHelper {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    static func paste() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
}
