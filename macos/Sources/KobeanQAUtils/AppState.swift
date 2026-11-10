import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTool: QATool = .base64
    @Published var searchText: String = ""
    @Published var toastMessage: String? = nil
    
    private var toastTask: Task<Void, Never>?
    
    func showToast(_ message: String) {
        toastMessage = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                withAnimation {
                    self.toastMessage = nil
                }
            }
        }
    }
    
    func copyAndToast(_ text: String, message: String = "Copied to clipboard!") {
        ClipboardHelper.copy(text)
        showToast(message)
    }
    
    func filteredTools(in category: ToolCategory) -> [QATool] {
        let tools = QATool.allCases.filter { $0.category == category }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return tools
        }
        let query = searchText.lowercased()
        return tools.filter { tool in
            tool.title.lowercased().contains(query) ||
            tool.subtitle.lowercased().contains(query) ||
            tool.searchKeywords.contains { $0.contains(query) }
        }
    }
    
    var hasSearchResults: Bool {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        for category in ToolCategory.allCases {
            if !filteredTools(in: category).isEmpty {
                return true
            }
        }
        return false
    }
}
