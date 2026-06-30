//
//  QuizViewModel.swift
//  StaffNotationQuizApp
//
//  Owns all quiz state: the question list, the current index, the running
//  score, feedback, and timing. The views are thin and just read from here.
//

import Foundation

@MainActor
final class QuizViewModel: ObservableObject {

    enum Phase {
        case idle
        case loading
        case active
        case finished
        case error(String)
    }

    enum Feedback: Equatable {
        case none
        case correct
        case incorrect
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var feedback: Feedback = .none
    @Published private(set) var selectedNote: Note?
    @Published private(set) var score = 0

    private let service: QuizService
    private var startTime: Date?
    private(set) var elapsed: TimeInterval = 0

    init(service: QuizService = FirebaseQuizService()) {
        self.service = service
    }

    // MARK: - Derived values

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var total: Int { questions.count }

    /// 1-based position for display, e.g. "Question 3 of 34".
    var questionNumber: Int { currentIndex + 1 }

    /// 0...1 progress through the quiz, for the progress bar.
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(currentIndex) / Double(total)
    }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return (Double(score) / Double(total)) * 100
    }

    // MARK: - Actions

    func startQuiz() async {
        phase = .loading
        feedback = .none
        selectedNote = nil
        score = 0
        currentIndex = 0
        do {
            let fetched = try await service.fetchQuestions()
            guard !fetched.isEmpty else {
                phase = .error("No questions were returned.")
                return
            }
            questions = fetched
            startTime = Date()
            phase = .active
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    /// Handle a tapped answer. Ignored while feedback is showing so the user
    /// can't double-answer the same question.
    func select(_ note: Note) {
        guard feedback == .none, let question = currentQuestion else { return }

        let isCorrect = note == question.correctAnswer
        selectedNote = note
        feedback = isCorrect ? .correct : .incorrect
        if isCorrect { score += 1 }

        Task {
            // Linger a touch longer so the reveal (correct/wrong) is visible.
            try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1s
            advance()
        }
    }

    func reset() {
        phase = .idle
        questions = []
        currentIndex = 0
        feedback = .none
        selectedNote = nil
        score = 0
        startTime = nil
        elapsed = 0
    }

    // MARK: - Internal

    private func advance() {
        feedback = .none
        selectedNote = nil
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            elapsed = Date().timeIntervalSince(startTime ?? Date())
            phase = .finished
        }
    }
}
