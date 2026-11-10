import SwiftUI
import AppKit

struct DummyDataGeneratorView: View {
    @EnvironmentObject private var appState: AppState
    
    enum OutputFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        case sql = "SQL INSERT"
        var id: String { rawValue }
    }
    
    struct MockField: Identifiable {
        let id: String
        let label: String
        var isSelected: Bool
    }
    
    @State private var fields: [MockField] = [
        MockField(id: "id", label: "ID (UUID)", isSelected: true),
        MockField(id: "fullName", label: "Full Name", isSelected: true),
        MockField(id: "email", label: "Email Address", isSelected: true),
        MockField(id: "phone", label: "Phone Number", isSelected: true),
        MockField(id: "jobTitle", label: "Job Title", isSelected: true),
        MockField(id: "company", label: "Company", isSelected: true),
        MockField(id: "city", label: "City", isSelected: true),
        MockField(id: "country", label: "Country", isSelected: true),
        MockField(id: "ipAddress", label: "IPv4 Address", isSelected: false),
        MockField(id: "creditCard", label: "Credit Card (Luhn)", isSelected: false),
        MockField(id: "dateOfBirth", label: "Date of Birth", isSelected: false)
    ]
    
    @State private var rowCount: Int = 10
    @State private var outputFormat: OutputFormat = .json
    @State private var tableName: String = "users"
    @State private var generatedOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .dummyData)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        Picker("Format", selection: $outputFormat) {
                            ForEach(OutputFormat.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .frame(maxWidth: 200)
                        
                        HStack(spacing: 8) {
                            Text("Rows:")
                                .font(.subheadline)
                            Stepper("\(rowCount)", value: $rowCount, in: 1...100)
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        
                        if outputFormat == .sql {
                            HStack(spacing: 6) {
                                Text("Table:")
                                    .font(.subheadline)
                                TextField("Table name", text: $tableName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            generateData()
                        } label: {
                            Label("Generate Data", systemImage: "sparkles")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut("g", modifiers: .command)
                    }
                    
                    Divider()
                    
                    // Fields Selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Included Columns:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button("Select All") {
                                for i in fields.indices { fields[i].isSelected = true }
                            }
                            .buttonStyle(.link)
                            Button("Deselect All") {
                                for i in fields.indices { fields[i].isSelected = false }
                            }
                            .buttonStyle(.link)
                        }
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 8) {
                            ForEach($fields) { $field in
                                Toggle(field.label, isOn: $field.isSelected)
                                    .toggleStyle(.checkbox)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Output Toolbar
                HStack {
                    Text("Generated Output (\(rowCount) records)")
                        .font(.headline)
                    Spacer()
                    
                    Button {
                        saveToFile()
                    } label: {
                        Label("Save File...", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(generatedOutput.isEmpty)
                    
                    Button {
                        ClipboardHelper.copy(generatedOutput)
                        appState.showToast("Copied \(outputFormat.rawValue) mock data")
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(generatedOutput.isEmpty)
                }
                
                // Output Preview
                TextEditor(text: $generatedOutput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 340)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            if generatedOutput.isEmpty {
                generateData()
            }
        }
    }
    
    // MARK: - Generator Engine
    private func generateData() {
        let selectedFields = fields.filter { $0.isSelected }
        guard !selectedFields.isEmpty else {
            generatedOutput = "// Please select at least one field to generate."
            return
        }
        
        var rows: [[String: String]] = []
        for _ in 0..<rowCount {
            var row: [String: String] = [:]
            for f in selectedFields {
                row[f.id] = generateMockValue(for: f.id)
            }
            rows.append(row)
        }
        
        switch outputFormat {
        case .json:
            renderJSON(rows, fields: selectedFields)
        case .csv:
            renderCSV(rows, fields: selectedFields)
        case .sql:
            renderSQL(rows, fields: selectedFields)
        }
    }
    
    private func renderJSON(_ rows: [[String: String]], fields: [MockField]) {
        if let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            generatedOutput = str
        }
    }
    
    private func renderCSV(_ rows: [[String: String]], fields: [MockField]) {
        var lines: [String] = []
        let header = fields.map { "\"\($0.id)\"" }.joined(separator: ",")
        lines.append(header)
        for r in rows {
            let rowLine = fields.map { f in
                let val = (r[f.id] ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(val)\""
            }.joined(separator: ",")
            lines.append(rowLine)
        }
        generatedOutput = lines.joined(separator: "\n")
    }
    
    private func renderSQL(_ rows: [[String: String]], fields: [MockField]) {
        let cols = fields.map { "`\($0.id)`" }.joined(separator: ", ")
        var stmts: [String] = []
        for r in rows {
            let vals = fields.map { f in
                let val = (r[f.id] ?? "").replacingOccurrences(of: "'", with: "''")
                return "'\(val)'"
            }.joined(separator: ", ")
            stmts.append("INSERT INTO `\(tableName)` (\(cols)) VALUES (\(vals));")
        }
        generatedOutput = stmts.joined(separator: "\n")
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        switch outputFormat {
        case .json:
            panel.nameFieldStringValue = "\(tableName).json"
        case .csv:
            panel.nameFieldStringValue = "\(tableName).csv"
        case .sql:
            panel.nameFieldStringValue = "\(tableName).sql"
        }
        if panel.runModal() == .OK, let url = panel.url {
            try? generatedOutput.write(to: url, atomically: true, encoding: .utf8)
            appState.showToast("Saved to \(url.lastPathComponent)")
        }
    }
    
    // MARK: - Realistic Mock Values
    private let firstNames = ["James", "Emma", "Liam", "Olivia", "Noah", "Ava", "Oliver", "Sophia", "Lucas", "Isabella", "Mateo", "Mia", "Alexander", "Charlotte", "Ethan", "Amelia", "Daniel", "Harper", "Michael", "Evelyn"]
    private let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin"]
    private let companies = ["Acme Corp", "Globex Inc", "Initech", "Soylent Corp", "Umbrella Labs", "Cyberdyne Systems", "Massive Dynamic", "Stark Industries", "Hooli", "Pied Piper", "Wayne Enterprises", "Oscorp", "Dunder Mifflin", "Aperture Science"]
    private let jobs = ["Senior QA Automation Engineer", "iOS Developer", "macOS Engineer", "DevOps Specialist", "Full-Stack Developer", "Product Manager", "Security Analyst", "Backend Architect", "Site Reliability Engineer", "Test Lead", "UI/UX Designer", "Scrum Master"]
    private let cities = ["San Francisco", "New York", "London", "Berlin", "Tokyo", "Paris", "Toronto", "Sydney", "Singapore", "Amsterdam", "Stockholm", "Austin", "Seattle", "Dublin"]
    private let countries = ["United States", "United Kingdom", "Germany", "Canada", "Australia", "Japan", "France", "Netherlands", "Sweden", "Singapore", "Ireland", "Switzerland"]
    
    private func generateMockValue(for id: String) -> String {
        switch id {
        case "id":
            return UUID().uuidString.lowercased()
        case "fullName":
            return "\(firstNames.randomElement()!) \(lastNames.randomElement()!)"
        case "email":
            let f = firstNames.randomElement()!.lowercased()
            let l = lastNames.randomElement()!.lowercased()
            let domains = ["example.com", "testmail.org", "qa-labs.io", "devcorp.net", "company.co"]
            return "\(f).\(l)\(Int.random(in: 10...99))@\(domains.randomElement()!)"
        case "phone":
            return String(format: "+1 (%03d) %03d-%04d", Int.random(in: 201...999), Int.random(in: 200...999), Int.random(in: 1000...9999))
        case "jobTitle":
            return jobs.randomElement()!
        case "company":
            return companies.randomElement()!
        case "city":
            return cities.randomElement()!
        case "country":
            return countries.randomElement()!
        case "ipAddress":
            return "\(Int.random(in: 11...223)).\(Int.random(in: 1...254)).\(Int.random(in: 1...254)).\(Int.random(in: 1...254))"
        case "creditCard":
            return generateLuhnCard()
        case "dateOfBirth":
            let year = Int.random(in: 1970...2004)
            let month = Int.random(in: 1...12)
            let day = Int.random(in: 1...28)
            return String(format: "%04d-%02d-%02d", year, month, day)
        default:
            return "Sample"
        }
    }
    
    private func generateLuhnCard() -> String {
        var digits: [Int] = [4] // Visa prefix
        for _ in 1...14 {
            digits.append(Int.random(in: 0...9))
        }
        // Calculate Luhn checksum
        var sum = 0
        for (idx, digit) in digits.enumerated() {
            var val = digit
            if idx % 2 == 1 {
                val *= 2
                if val > 9 { val -= 9 }
            }
            sum += val
        }
        let checkDigit = (10 - (sum % 10)) % 10
        digits.append(checkDigit)
        let s = digits.map { String($0) }.joined()
        return "\(s.prefix(4)) \(s.dropFirst(4).prefix(4)) \(s.dropFirst(8).prefix(4)) \(s.suffix(4))"
    }
}
