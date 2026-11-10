import SwiftUI
import AppKit

struct QAStudyCard: Identifiable, Codable {
    var id: UUID = UUID()
    let category: String
    let front: String
    let back: String
    let mnemonic: String?
    var easeFactor: Double = 2.5
    var interval: Int = 1
    var repetitions: Int = 0
}

struct FlashcardsView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var cards: [QAStudyCard] = [
        QAStudyCard(
            category: "ISTQB Principles",
            front: "What is Principle 1: Testing shows the presence of defects?",
            back: "Testing can prove defects are present, but cannot prove that software is defect-free. Even extensive testing reduces probability of undiscovered defects, but is not proof of absolute correctness.",
            mnemonic: "Presence, not absence."
        ),
        QAStudyCard(
            category: "ISTQB Principles",
            front: "What is Principle 2: Exhaustive testing is impossible?",
            back: "Testing everything (all combinations of inputs and preconditions) is not feasible except for trivial cases. Instead, risk analysis, test techniques, and priorities should be used to focus test efforts.",
            mnemonic: "Risk-based, not exhaustive."
        ),
        QAStudyCard(
            category: "ISTQB Principles",
            front: "What is Principle 6: Testing is context dependent?",
            back: "Testing is done differently in different contexts. For example, safety-critical medical or aviation software is tested differently from an e-commerce mobile application.",
            mnemonic: "Context dictates rigor."
        ),
        QAStudyCard(
            category: "Test Techniques",
            front: "What is Boundary Value Analysis (BVA)?",
            back: "A black-box test technique based on testing boundaries of equivalence partitions. Boundaries are where defects are most commonly found (Min, Min+1, Max-1, Max).",
            mnemonic: "Edges have bugs."
        ),
        QAStudyCard(
            category: "Test Techniques",
            front: "What is Equivalence Partitioning (EP)?",
            back: "Divides input data into valid and invalid partitions where all members are treated identically by the software. Testing one value from each partition represents the whole class.",
            mnemonic: "Group similar inputs."
        ),
        QAStudyCard(
            category: "Test Levels",
            front: "What are the 4 standard ISTQB Test Levels?",
            back: "1. Component (Unit) Testing\n2. Integration Testing\n3. System Testing\n4. Acceptance Testing (UAT)",
            mnemonic: "C-I-S-A"
        )
    ]
    
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var cardsReviewed: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ToolHeaderView(tool: .flashcards)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Progress & Category Header
            HStack {
                Text("Card \(currentIndex + 1) of \(cards.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(currentCard.category)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 24)
            
            // Flashcard Flip Canvas
            ZStack {
                if !isFlipped {
                    cardFace(title: "QUESTION", content: currentCard.front, hint: "Click to reveal answer", isFront: true)
                } else {
                    cardFace(title: "ANSWER", content: currentCard.back, hint: currentCard.mnemonic.map { "Mnemonic: " + $0 } ?? "", isFront: false)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(.horizontal, 24)
            .onTapGesture {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    isFlipped.toggle()
                }
            }
            
            // Rating Controls
            if isFlipped {
                HStack(spacing: 12) {
                    Spacer()
                    rateButton(label: "Again", quality: 1, color: .red)
                    rateButton(label: "Hard", quality: 2, color: .orange)
                    rateButton(label: "Good", quality: 4, color: .blue)
                    rateButton(label: "Easy", quality: 5, color: .green)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .transition(.opacity)
            } else {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isFlipped = true }
                    } label: {
                        Text("Show Answer (Space)")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.space, modifiers: [])
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
    
    private var currentCard: QAStudyCard {
        cards[currentIndex % cards.count]
    }
    
    private func cardFace(title: String, content: String, hint: String, isFront: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: isFront ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill")
                    .foregroundColor(.accentColor)
            }
            
            Text(content)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if !hint.isEmpty {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(isFront ? .secondary : .accentColor)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private func rateButton(label: String, quality: Int, color: Color) -> some View {
        Button {
            applySm2(quality: quality)
        } label: {
            Text(label)
                .fontWeight(.medium)
                .frame(minWidth: 80)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }
    
    private func applySm2(quality: Int) {
        var card = currentCard
        if quality < 3 {
            card.repetitions = 0
            card.interval = 1
        } else {
            if card.repetitions == 0 {
                card.interval = 1
            } else if card.repetitions == 1 {
                card.interval = 6
            } else {
                card.interval = Int(Double(card.interval) * card.easeFactor)
            }
            card.repetitions += 1
        }
        let q = Double(quality)
        let newEf = card.easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        card.easeFactor = max(1.3, newEf)
        
        cards[currentIndex] = card
        cardsReviewed += 1
        isFlipped = false
        currentIndex = (currentIndex + 1) % cards.count
        appState.showToast("Next review in \(card.interval) day(s)")
    }
}
