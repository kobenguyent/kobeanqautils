import SwiftUI
import Combine

struct TimestampConverterView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var currentSeconds: Int64 = Int64(Date().timeIntervalSince1970)
    @State private var currentMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    @State private var inputTimestamp: String = "\(Int64(Date().timeIntervalSince1970))"
    @State private var isMilliseconds: Bool = false
    
    @State private var selectedDate: Date = Date()
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private var convertedDate: Date? {
        guard let num = Double(inputTimestamp.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let sec = isMilliseconds ? (num / 1000.0) : num
        return Date(timeIntervalSince1970: sec)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .timestamp) {
                    inputTimestamp = "\(Int64(Date().timeIntervalSince1970))"
                    isMilliseconds = false
                    selectedDate = Date()
                }
                
                // Live Current Epoch Banner
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Unix Epoch (Seconds)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentSeconds)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Unix Epoch (Milliseconds)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentMillis)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    Button("Copy Seconds") {
                        appState.copyAndToast("\(currentSeconds)")
                    }
                }
                .padding()
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(10)
                
                // Epoch to Human Date Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unix Timestamp ➔ Human Date")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        TextField("Timestamp (e.g. 1700000000)", text: $inputTimestamp)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        
                        Picker("", selection: $isMilliseconds) {
                            Text("Seconds").tag(false)
                            Text("Milliseconds").tag(true)
                        }
                        .frame(width: 140)
                        
                        Button("Use Now") {
                            inputTimestamp = "\(Int64(Date().timeIntervalSince1970))"
                            isMilliseconds = false
                        }
                    }
                    
                    if let date = convertedDate {
                        VStack(spacing: 8) {
                            row(title: "Local Time", value: date.formatted(date: .complete, time: .complete))
                            row(title: "UTC (GMT)", value: utcFormatted(date))
                            row(title: "ISO 8601", value: ISO8601DateFormatter().string(from: date))
                            row(title: "Relative", value: relativeFormatted(date))
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        Text("Enter a valid numerical timestamp")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
                
                // Human Date to Epoch Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Human Date ➔ Unix Timestamp")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker("Select Date & Time:", selection: $selectedDate)
                        .datePickerStyle(.graphical)
                        .frame(maxWidth: 320)
                    
                    let sec = Int64(selectedDate.timeIntervalSince1970)
                    let ms = Int64(selectedDate.timeIntervalSince1970 * 1000)
                    
                    VStack(spacing: 8) {
                        row(title: "Seconds", value: "\(sec)")
                        row(title: "Milliseconds", value: "\(ms)")
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
            }
            .padding(20)
        }
        .onReceive(timer) { _ in
            let now = Date()
            currentSeconds = Int64(now.timeIntervalSince1970)
            currentMillis = Int64(now.timeIntervalSince1970 * 1000)
        }
    }
    
    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
            Button(action: {
                appState.copyAndToast(value)
            }) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
        }
    }
    
    private func utcFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        return f.string(from: date)
    }
    
    private func relativeFormatted(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
}
