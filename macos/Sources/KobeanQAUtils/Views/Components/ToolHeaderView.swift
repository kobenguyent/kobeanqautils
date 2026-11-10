import SwiftUI

struct ToolHeaderView: View {
    let tool: QATool
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: tool.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(tool.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let onReset = onReset {
                Button(action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Reset to default")
            }
        }
        .padding(.bottom, 12)
    }
}
