import SwiftUI
import AppKit
import Combine

struct ExamQuestion: Identifiable {
    let id: Int
    let chapter: Int
    let kLevel: String
    let text: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let syllabusRef: String
}

struct ISTQBPracticeExamView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var currentIndex: Int = 0
    @State private var selectedAnswers: [Int: Int] = [:] // Question id -> selected option index
    @State private var flaggedQuestions: Set<Int> = []
    @State private var isExamSubmitted: Bool = false
    @State private var timeRemainingSeconds: Int = 2400 // 40 minutes
    @State private var timerActive: Bool = false
    @State private var practiceMode: Bool = true // if true, show answer immediately
    @State private var filterChapter: Int = 0 // 0 = all
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let questions: [ExamQuestion] = [
        ExamQuestion(
            id: 1,
            chapter: 1,
            kLevel: "K1",
            text: "Which of the following statements describe a valid test objective according to ISTQB CTFL v4?",
            options: [
                "To prove that there are no unfixed defects remaining in the software under test",
                "To prove that no failures will occur in production after release",
                "To reduce the risk level of the test object and to build confidence in the quality level",
                "To verify that every possible combination of inputs has been tested"
            ],
            correctIndex: 2,
            explanation: "Testing reduces risk and builds confidence (Principle 1 & 2: Exhaustive testing is impossible, testing shows the presence of defects, not their absence).",
            syllabusRef: "FL-1.1.1 (K1)"
        ),
        ExamQuestion(
            id: 2,
            chapter: 1,
            kLevel: "K2",
            text: "Which of the following is an example of a failure caused by a defect?",
            options: [
                "A developer mistypes a variable name in the source code",
                "An automated batch job crashes with a Segmentation Fault at midnight",
                "A product owner specifies contradictory acceptance criteria in Jira",
                "A QA tester writes an ambiguous test step in a test case"
            ],
            correctIndex: 1,
            explanation: "A human makes an ERROR (mistake), which introduces a DEFECT (bug/fault) in code, which when executed causes an observable FAILURE (crash or incorrect behavior).",
            syllabusRef: "FL-1.2.1 (K2)"
        ),
        ExamQuestion(
            id: 3,
            chapter: 2,
            kLevel: "K2",
            text: "In the Context of Test-Driven Development (TDD), which sequence is correct?",
            options: [
                "Write code -> Write automated test -> Run test -> Refactor",
                "Write automated test -> Run test (fail) -> Write code -> Run test (pass) -> Refactor",
                "Design architecture -> Write integration test -> Write code -> Run manual test",
                "Write acceptance criteria -> Manual smoke test -> Write automated unit test"
            ],
            correctIndex: 1,
            explanation: "TDD follows the Red-Green-Refactor cycle: First write an automated test that fails (Red), write code to make it pass (Green), then clean up code (Refactor).",
            syllabusRef: "FL-2.1.2 (K2)"
        ),
        ExamQuestion(
            id: 4,
            chapter: 3,
            kLevel: "K2",
            text: "Which of the following is a primary benefit of Static Testing compared to Dynamic Testing?",
            options: [
                "It executes test code on live databases to catch network timeouts",
                "Defects are discovered earlier in the SDLC, making them significantly cheaper to fix",
                "It guarantees 100% path coverage of compiled binaries",
                "It replaces the need for performance and load testing"
            ],
            correctIndex: 1,
            explanation: "Static testing (reviews and static code analysis) finds defects before code execution, drastically lowering remediation costs and defect propagation.",
            syllabusRef: "FL-3.1.2 (K2)"
        ),
        ExamQuestion(
            id: 5,
            chapter: 4,
            kLevel: "K3",
            text: "An input field accepts integer values between 18 and 65 (inclusive) for age eligibility. Using 2-point Boundary Value Analysis (BVA), which values should be tested?",
            options: [
                "17, 18, 65, 66",
                "18, 19, 64, 65",
                "0, 18, 65, 100",
                "17, 18, 19, 64, 65, 66"
            ],
            correctIndex: 0,
            explanation: "In 2-point BVA, the boundary values are the boundary itself and its immediate outside neighbor: {17, 18} for lower boundary, and {65, 66} for upper boundary.",
            syllabusRef: "FL-4.2.2 (K3)"
        ),
        ExamQuestion(
            id: 6,
            chapter: 4,
            kLevel: "K3",
            text: "A login form locks an account after 3 consecutive failed attempts. Which test design technique is most suitable to model this behavior?",
            options: [
                "Equivalence Partitioning",
                "State Transition Testing",
                "Decision Table Testing",
                "Boundary Value Analysis"
            ],
            correctIndex: 1,
            explanation: "State Transition Testing is ideal when system outputs and states depend on previous history and event sequences (e.g. Counter = 0 -> 1 -> 2 -> Locked).",
            syllabusRef: "FL-4.2.4 (K3)"
        ),
        ExamQuestion(
            id: 7,
            chapter: 5,
            kLevel: "K2",
            text: "Which of the following represents an entry criterion for System Testing?",
            options: [
                "All high-priority defects found in production have been resolved",
                "The test environment is provisioned and smoke test passes",
                "Test summary report has been signed off by the QA director",
                "Automated regression suite runtime is under 5 minutes"
            ],
            correctIndex: 1,
            explanation: "Entry criteria define prerequisites before a test level can start (e.g., test environment availability, build deployed, unit test completion).",
            syllabusRef: "FL-5.1.3 (K2)"
        ),
        ExamQuestion(
            id: 8,
            chapter: 6,
            kLevel: "K1",
            text: "Which risk is associated with the introduction of automated test execution tools?",
            options: [
                "Over-reliance on the tool and unrealistic expectations of tool capabilities",
                "Inability to run tests repeatedly during continuous integration",
                "Reduced speed in executing large repetitive test suites",
                "Elimination of human bias in exploratory testing"
            ],
            correctIndex: 0,
            explanation: "Common risks of test automation include unrealistic ROI expectations, underestimating maintenance effort, and thinking tools replace skilled human testing.",
            syllabusRef: "FL-6.2.1 (K1)"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .istqbExam, onReset: resetExam)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Exam Header Toolbar
            HStack(spacing: 16) {
                // Timer
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(timeRemainingSeconds < 300 ? .red : .accentColor)
                    Text(formattedTime)
                        .font(.system(.headline, design: .monospaced))
                }
                
                Toggle("Practice Mode (Show Answers)", isOn: $practiceMode)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Spacer()
                
                // Flag toggle
                if let cur = currentQuestion {
                    Button(action: {
                        if flaggedQuestions.contains(cur.id) {
                            flaggedQuestions.remove(cur.id)
                        } else {
                            flaggedQuestions.insert(cur.id)
                        }
                    }) {
                        Label(
                            flaggedQuestions.contains(cur.id) ? "Flagged" : "Flag",
                            systemImage: flaggedQuestions.contains(cur.id) ? "flag.fill" : "flag"
                        )
                        .foregroundColor(flaggedQuestions.contains(cur.id) ? .orange : .secondary)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Submit Button
                if !isExamSubmitted {
                    Button(action: submitExam) {
                        Label("Submit Exam", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Button(action: resetExam) {
                        Label("Retake Exam", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            HSplitView {
                // Left: Question Navigator Grid
                VStack(spacing: 8) {
                    Text("QUESTION PALETTE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { idx, q in
                                Button(action: { currentIndex = idx }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(paletteColor(for: q, index: idx))
                                            .frame(width: 40, height: 40)
                                        
                                        Text("\(q.id)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(paletteTextColor(for: q, index: idx))
                                        
                                        if flaggedQuestions.contains(q.id) {
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Circle()
                                                        .fill(Color.orange)
                                                        .frame(width: 6, height: 6)
                                                }
                                                Spacer()
                                            }
                                            .padding(3)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                    }
                    
                    Divider()
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 4) {
                        legendItem(color: .accentColor, label: "Current Question")
                        legendItem(color: .green.opacity(0.3), label: "Answered")
                        legendItem(color: .orange, label: "Flagged")
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                .frame(width: 200)
                
                // Right: Active Question & Choices
                VStack(spacing: 0) {
                    if isExamSubmitted {
                        examScoreSummaryView
                    } else if let q = currentQuestion {
                        questionDetailView(q)
                    }
                }
                .frame(minWidth: 450)
            }
        }
        .onReceive(timer) { _ in
            if !isExamSubmitted && timeRemainingSeconds > 0 {
                timeRemainingSeconds -= 1
            } else if timeRemainingSeconds == 0 && !isExamSubmitted {
                submitExam()
            }
        }
    }
    
    // MARK: - Current Question Helpers
    private var currentQuestion: ExamQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    private var formattedTime: String {
        let min = timeRemainingSeconds / 60
        let sec = timeRemainingSeconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
    
    // MARK: - Question Detail View
    @ViewBuilder
    private func questionDetailView(_ q: ExamQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Question Header Tags
                HStack(spacing: 8) {
                    Text("Question \(currentIndex + 1) of \(questions.count)")
                        .font(.headline)
                    
                    Text("Chapter \(q.chapter)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text(q.kLevel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(q.syllabusRef)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Question Text
                Text(q.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineSpacing(4)
                
                Divider()
                
                // Options (A, B, C, D)
                VStack(spacing: 10) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { optIndex, optionText in
                        Button(action: {
                            selectedAnswers[q.id] = optIndex
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                Text(letterForIndex(optIndex))
                                    .font(.headline)
                                    .foregroundColor(optionPrefixColor(q: q, optIndex: optIndex))
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(optionText)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedAnswers[q.id] == optIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(optionBackground(q: q, optIndex: optIndex))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedAnswers[q.id] == optIndex ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Explanation in Practice Mode
                if practiceMode && selectedAnswers[q.id] != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedAnswers[q.id] == q.correctIndex ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundColor(selectedAnswers[q.id] == q.correctIndex ? .green : .red)
                            Text(selectedAnswers[q.id] == q.correctIndex ? "Correct Answer!" : "Incorrect Answer")
                                .font(.headline)
                                .foregroundColor(selectedAnswers[q.id] == q.correctIndex ? .green : .red)
                        }
                        
                        Text(q.explanation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Next / Prev controls
                HStack {
                    Button("Previous") {
                        if currentIndex > 0 { currentIndex -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    Button("Next") {
                        if currentIndex < questions.count - 1 { currentIndex += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentIndex == questions.count - 1)
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }
    
    // MARK: - Score Summary View
    @ViewBuilder
    private var examScoreSummaryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pass/Fail Banner
                let score = calculateScore()
                let passed = score.percentage >= 65.0
                
                VStack(spacing: 8) {
                    Image(systemName: passed ? "trophy.fill" : "exclamationmark.octagon.fill")
                        .font(.system(size: 52))
                        .foregroundColor(passed ? .yellow : .red)
                    
                    Text(passed ? "Congratulations! You Passed!" : "Needs Improvement")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(passed ? "You achieved the 65% ISTQB CTFL passing threshold." : "The official ISTQB pass mark is 65% (26 of 40 questions).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Stats Grid
                HStack(spacing: 14) {
                    statTile(title: "SCORE", value: "\(score.correct) / \(questions.count)", color: .accentColor)
                    statTile(title: "PERCENTAGE", value: String(format: "%.1f%%", score.percentage), color: passed ? .green : .red)
                    statTile(title: "RESULT", value: passed ? "PASSED" : "FAILED", color: passed ? .green : .red)
                }
                .padding(.horizontal)
                
                // Review Missed Questions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Question by Question Review")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(questions) { q in
                            let userChoice = selectedAnswers[q.id]
                            let isCorrect = userChoice == q.correctIndex
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Q\(q.id): \(q.text)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack {
                                        Text("Your: \(userChoice != nil ? letterForIndex(userChoice!) : "None")")
                                            .font(.caption)
                                            .foregroundColor(isCorrect ? .green : .red)
                                        Text("Correct: \(letterForIndex(q.correctIndex))")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text(q.explanation)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helpers
    private func letterForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "A"
        case 1: return "B"
        case 2: return "C"
        case 3: return "D"
        default: return ""
        }
    }
    
    private func calculateScore() -> (correct: Int, percentage: Double) {
        var correct = 0
        for q in questions {
            if selectedAnswers[q.id] == q.correctIndex {
                correct += 1
            }
        }
        let pct = Double(correct) / Double(questions.count) * 100.0
        return (correct, pct)
    }
    
    private func submitExam() {
        isExamSubmitted = true
        appState.showToast("Exam submitted. Review your score below.")
    }
    
    private func resetExam() {
        currentIndex = 0
        selectedAnswers = [:]
        flaggedQuestions = []
        isExamSubmitted = false
        timeRemainingSeconds = 2400
    }
    
    private func paletteColor(for q: ExamQuestion, index: Int) -> Color {
        if index == currentIndex {
            return Color.accentColor
        }
        if selectedAnswers[q.id] != nil {
            return Color.green.opacity(0.2)
        }
        return Color(NSColor.controlBackgroundColor)
    }
    
    private func paletteTextColor(for q: ExamQuestion, index: Int) -> Color {
        if index == currentIndex { return .white }
        return .primary
    }
    
    private func optionPrefixColor(q: ExamQuestion, optIndex: Int) -> Color {
        if practiceMode && selectedAnswers[q.id] != nil {
            if optIndex == q.correctIndex { return .green }
            if selectedAnswers[q.id] == optIndex { return .red }
        }
        return .primary
    }
    
    private func optionBackground(q: ExamQuestion, optIndex: Int) -> Color {
        if practiceMode && selectedAnswers[q.id] != nil {
            if optIndex == q.correctIndex { return Color.green.opacity(0.12) }
            if selectedAnswers[q.id] == optIndex { return Color.red.opacity(0.12) }
        }
        return Color(NSColor.controlBackgroundColor)
    }
    
    @ViewBuilder
    private func statTile(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
