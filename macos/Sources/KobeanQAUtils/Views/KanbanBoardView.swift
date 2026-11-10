import SwiftUI
import AppKit

struct KanbanTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var priority: Priority
    var tag: String
    var status: TaskStatus
    
    enum Priority: String, CaseIterable, Codable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    enum TaskStatus: String, CaseIterable, Codable, Identifiable {
        case backlog = "Backlog"
        case inProgress = "In Progress"
        case testing = "QA Testing"
        case done = "Done"
        var id: String { rawValue }
    }
}

struct KanbanBoardView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var tasks: [KanbanTask] = [
        KanbanTask(title: "Migrate Web Tools to Pure Native SwiftUI", priority: .critical, tag: "macOS", status: .inProgress),
        KanbanTask(title: "Verify Apple HIG 1024x1024 Squircle Branding", priority: .high, tag: "Branding", status: .done),
        KanbanTask(title: "Add WebSocket and gRPC Network Clients", priority: .high, tag: "Network", status: .testing),
        KanbanTask(title: "Write Test File Generator with Chunk Streaming", priority: .medium, tag: "QA Engine", status: .done),
        KanbanTask(title: "Implement ISTQB Spaced Repetition Learning", priority: .low, tag: "Study", status: .backlog)
    ]
    
    @State private var showNewTaskModal: Bool = false
    @State private var newTitle: String = ""
    @State private var newPriority: KanbanTask.Priority = .medium
    @State private var newTag: String = "Feature"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .kanbanBoard)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Header Action
            HStack {
                Text("Native QA Project Board")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showNewTaskModal = true
                } label: {
                    Label("New Task", systemImage: "plus")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            
            // 4 Kanban Columns
            GeometryReader { geo in
                let colWidth = (geo.size.width - 48 - (12 * 3)) / 4
                
                HStack(alignment: .top, spacing: 12) {
                    ForEach(KanbanTask.TaskStatus.allCases) { status in
                        kanbanColumn(status: status, width: colWidth)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showNewTaskModal) {
            newTaskSheet
        }
        .onAppear {
            loadTasks()
        }
    }
    
    private func kanbanColumn(status: KanbanTask.TaskStatus, width: CGFloat) -> some View {
        let colTasks = tasks.filter { $0.status == status }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(status.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(colTasks.count)")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if colTasks.isEmpty {
                        Text("No tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(colTasks) { task in
                            taskCard(task)
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: width)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
    
    private func taskCard(_ task: KanbanTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.tag)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(4)
                
                Spacer()
                
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
                Text(task.priority.rawValue)
                    .font(.caption2)
                    .foregroundColor(task.priority.color)
            }
            
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)
            
            // Move buttons
            HStack {
                if let prev = previousStatus(task.status) {
                    Button {
                        moveTask(task, to: prev)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                Button {
                    deleteTask(task)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                
                if let next = nextStatus(task.status) {
                    Button {
                        moveTask(task, to: next)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
    
    private var newTaskSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Task")
                .font(.headline)
            
            TextField("Task title", text: $newTitle)
                .textFieldStyle(.roundedBorder)
            
            HStack(spacing: 16) {
                Picker("Priority", selection: $newPriority) {
                    ForEach(KanbanTask.Priority.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                
                TextField("Tag (e.g. Bug, Feature)", text: $newTag)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showNewTaskModal = false
                }
                .buttonStyle(.bordered)
                
                Button("Add Task") {
                    if !newTitle.isEmpty {
                        let t = KanbanTask(title: newTitle, priority: newPriority, tag: newTag.isEmpty ? "Task" : newTag, status: .backlog)
                        tasks.append(t)
                        saveTasks()
                        newTitle = ""
                        showNewTaskModal = false
                        appState.showToast("Task added to Backlog")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTitle.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
    
    private func previousStatus(_ status: KanbanTask.TaskStatus) -> KanbanTask.TaskStatus? {
        switch status {
        case .backlog: return nil
        case .inProgress: return .backlog
        case .testing: return .inProgress
        case .done: return .testing
        }
    }
    
    private func nextStatus(_ status: KanbanTask.TaskStatus) -> KanbanTask.TaskStatus? {
        switch status {
        case .backlog: return .inProgress
        case .inProgress: return .testing
        case .testing: return .done
        case .done: return nil
        }
    }
    
    private func moveTask(_ task: KanbanTask, to next: KanbanTask.TaskStatus) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].status = next
            saveTasks()
        }
    }
    
    private func deleteTask(_ task: KanbanTask) {
        tasks.removeAll(where: { $0.id == task.id })
        saveTasks()
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "kobean_kanban_tasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "kobean_kanban_tasks"),
           let saved = try? JSONDecoder().decode([KanbanTask].self, from: data) {
            tasks = saved
        }
    }
}
