//
//  QuizViewModel.swift
//  StaffNotationQuizApp
//
//  Owns all quiz state: the question list, current index, running score,
//  feedback, a live stopwatch, and pause/resume/end control.
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
    @Published private(set) var answeredCount = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isPaused = false
    @Published private(set) var mode: QuizMode = .notation

    private let service: QuizService

    // Stopwatch: total = accumulated (completed segments) + time since segmentStart.
    private var timer: Timer?
    private var segmentStart: Date?
    private var accumulated: TimeInterval = 0

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

    /// Accuracy over the questions actually answered (so ending early is fair).
    var accuracy: Double {
        guard answeredCount > 0 else { return 0 }
        return (Double(score) / Double(answeredCount)) * 100
    }

    // MARK: - Lifecycle

    func startQuiz(mode: QuizMode = .notation) async {
        self.mode = mode
        stopTimer()
        phase = .loading
        feedback = .none
        selectedNote = nil
        score = 0
        answeredCount = 0
        currentIndex = 0
        accumulated = 0
        elapsed = 0
        isPaused = false
        do {
            let fetched = try await service.fetchQuestions()
            guard !fetched.isEmpty else {
                phase = .error("No questions were returned.")
                return
            }
            questions = fetched          // already shuffled by the service
            phase = .active
            startTimer()
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func reset() {
        stopTimer()
        phase = .idle
        questions = []
        currentIndex = 0
        feedback = .none
        selectedNote = nil
        score = 0
        answeredCount = 0
        accumulated = 0
        elapsed = 0
        isPaused = false
    }

    // MARK: - Answering

    /// Handle a tapped answer. Ignored while feedback shows or while paused.
    func select(_ note: Note) {
        guard feedback == .none, !isPaused, let question = currentQuestion else { return }

        let isCorrect = note == question.correctAnswer
        selectedNote = note
        feedback = isCorrect ? .correct : .incorrect
        answeredCount += 1
        if isCorrect { score += 1 }

        Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1s
            advance()
        }
    }

    // MARK: - Pause / resume / end

    func pause() {
        guard !isPaused, segmentStart != nil else { return }
        accumulateSegment()
        stopTimer()
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        startTimer()
    }

    /// End the quiz immediately and show results with progress so far.
    func endQuiz() {
        finalize()
    }

    // MARK: - Internal

    private func advance() {
        guard !isPaused else { return }   // don't move on behind the pause screen
        feedback = .none
        selectedNote = nil
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            finalize()
        }
    }

    private func finalize() {
        if !isPaused { accumulateSegment() }
        stopTimer()
        elapsed = accumulated
        feedback = .none
        selectedNote = nil
        isPaused = false
        phase = .finished
    }

    // MARK: - Stopwatch

    private func startTimer() {
        stopTimer()
        segmentStart = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let start = segmentStart else { return }
        elapsed = accumulated + Date().timeIntervalSince(start)
    }

    private func accumulateSegment() {
        guard let start = segmentStart else { return }
        accumulated += Date().timeIntervalSince(start)
        segmentStart = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
