import SwiftUI

struct SQLHelperView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var inputSQL: String = "select id, name, email, created_at from users where status = 'active' and created_at > '2024-01-01' order by id desc limit 50;"
    @State private var outputSQL: String = ""
    
    // Mock insert builder
    @State private var tableName: String = "test_users"
    @State private var columns: String = "id, username, email, is_active"
    @State private var rowCount: Double = 5
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolHeaderView(tool: .sqlHelper) {
                    inputSQL = ""
                    outputSQL = ""
                }
                
                // Formatter Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SQL Formatter")
                            .font(.headline)
                        Spacer()
                        Button("Format SQL") {
                            formatSQL()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Copy Output") {
                            appState.copyAndToast(outputSQL)
                        }
                        .disabled(outputSQL.isEmpty)
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Input Query")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $inputSQL)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 120)
                                .padding(6)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Formatted Query")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: .constant(outputSQL))
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 120)
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
                
                // Mock Insert Generator Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mock INSERT Statements Generator")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Table Name:")
                                .font(.caption)
                            TextField("table_name", text: $tableName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Columns (comma-separated):")
                                .font(.caption)
                            TextField("id, name, ...", text: $columns)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rows: \(Int(rowCount))")
                                .font(.caption)
                            Stepper("", value: $rowCount, in: 1...30)
                        }
                        
                        Button("Generate Mock SQL") {
                            generateMockInserts()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 14)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
            }
            .padding(20)
        }
        .onAppear {
            formatSQL()
        }
    }
    
    private func formatSQL() {
        var sql = inputSQL
        let keywords = [
            "SELECT", "FROM", "WHERE", "AND", "OR", "INNER JOIN", "LEFT JOIN",
            "RIGHT JOIN", "JOIN", "ON", "GROUP BY", "ORDER BY", "HAVING",
            "LIMIT", "OFFSET", "INSERT INTO", "VALUES", "UPDATE", "SET",
            "DELETE FROM", "CREATE TABLE", "DROP TABLE", "ALTER TABLE"
        ]
        
        for kw in keywords {
            let pattern = "\\b" + kw + "\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: sql.utf16.count)
                sql = regex.stringByReplacingMatches(in: sql, options: [], range: range, withTemplate: "\n" + kw)
            }
        }
        
        // Clean leading whitespace/newlines
        let lines = sql.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        outputSQL = lines.joined(separator: "\n")
    }
    
    private func generateMockInserts() {
        let cols = columns.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let count = Int(rowCount)
        var statements: [String] = []
        
        for i in 1...count {
            let values = cols.map { col -> String in
                if col.lowercased().contains("id") { return "\(i)" }
                if col.lowercased().contains("email") { return "'user\(i)@example.com'" }
                if col.lowercased().contains("active") || col.lowercased().contains("is_") { return "TRUE" }
                return "'\(col)_\(i)'"
            }
            statements.append("INSERT INTO \(tableName) (\(cols.joined(separator: ", "))) VALUES (\(values.joined(separator: ", ")));")
        }
        outputSQL = statements.joined(separator: "\n")
    }
}
