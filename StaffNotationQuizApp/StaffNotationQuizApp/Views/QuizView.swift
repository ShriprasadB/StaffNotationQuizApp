//
//  QuizView.swift
//  StaffNotationQuizApp
//
//  Active quiz screen. Adapts between a stacked layout (portrait) and a
//  side-by-side layout (landscape), reveals the correct/wrong answer, and
//  fires haptics on each result.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.horizontalSizeClass) private var hSize

    enum AnswerVisual { case idle, correct, wrong, dimmed }

    var body: some View {
        let isLandscape = vSize == .compact
        let layout = isLandscape
            ? AnyLayout(HStackLayout(spacing: 28))
            : AnyLayout(VStackLayout(spacing: 20))

        VStack(spacing: 16) {
            progressHeader

            layout {
                imageCard
                VStack(spacing: 16) {
                    feedbackBanner
                    answerGrid
                }
            }
        }
        .padding(.vertical, 16)
        .onChange(of: viewModel.feedback) { fb in
            switch fb {
            case .correct: Haptics.success()
            case .incorrect: Haptics.error()
            case .none: break
            }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(viewModel.questionNumber) of \(viewModel.total)")
                Spacer()
                Label("\(viewModel.score)", systemImage: "star.fill")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25))
                    Capsule()
                        .fill(.white)
                        .frame(width: max(8, geo.size.width * progressFraction))
                }
            }
            .frame(height: 8)
        }
    }

    // Fill the bar including the current (in-progress) question.
    private var progressFraction: Double {
        guard viewModel.total > 0 else { return 0 }
        return Double(viewModel.questionNumber) / Double(viewModel.total)
    }

    // MARK: - Image

    private var imageCard: some View {
        VStack(spacing: 0) {
            if let question = viewModel.currentQuestion {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: question.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(Theme.primary)
                        case .success(let image):
                            image.resizable().scaledToFit().padding(20)
                        case .failure:
                            Image(systemName: "wifi.exclamationmark")
                                .font(.largeTitle).foregroundColor(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: vSize == .compact ? 200 : 240)
                    .background(Color.white)

                    if let clef = question.clef {
                        Text(clef.capitalized + " clef")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.primary, in: Capsule())
                            .padding(12)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        .id(viewModel.currentIndex)               // re-create per question
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackBanner: some View {
        Group {
            switch viewModel.feedback {
            case .correct:
                banner(text: "Correct!", icon: "checkmark.circle.fill", color: Theme.correct)
            case .incorrect:
                banner(text: "Not quite", icon: "xmark.circle.fill", color: Theme.incorrect)
            case .none:
                Color.clear
            }
        }
        .frame(height: 44)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.feedback)
    }

    private func banner(text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(color, in: Capsule())
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Answers

    private var answerGrid: some View {
        let minWidth: CGFloat = hSize == .regular ? 110 : 76
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: 12)], spacing: 12) {
            ForEach(Note.allCases) { note in
                answerButton(note)
            }
        }
    }

    private func answerButton(_ note: Note) -> some View {
        let v = visual(for: note)
        return Button {
            viewModel.select(note)
        } label: {
            Text(note.rawValue)
                .font(.title.bold())
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundColor(foreground(v))
                .background(background(v))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .scaleEffect(v == .correct ? 1.06 : 1)
                .opacity(v == .dimmed ? 0.45 : 1)
        }
        .disabled(viewModel.feedback != .none)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.feedback)
    }

    private func visual(for note: Note) -> AnswerVisual {
        guard viewModel.feedback != .none,
              let correct = viewModel.currentQuestion?.correctAnswer else { return .idle }
        if note == correct { return .correct }
        if note == viewModel.selectedNote { return .wrong }
        return .dimmed
    }

    private func foreground(_ v: AnswerVisual) -> Color {
        switch v {
        case .idle, .dimmed: return Theme.primaryDark
        case .correct, .wrong: return .white
        }
    }

    @ViewBuilder
    private func background(_ v: AnswerVisual) -> some View {
        switch v {
        case .idle, .dimmed: Color.white
        case .correct: Theme.correct
        case .wrong: Theme.incorrect
        }
    }
}
