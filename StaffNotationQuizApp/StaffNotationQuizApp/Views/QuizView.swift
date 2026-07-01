//
//  QuizView.swift
//  StaffNotationQuizApp
//
//  Active quiz screen. Adapts between stacked (portrait) and side-by-side
//  (landscape) layouts, shows a live timer with pause/end controls, reveals
//  the correct/wrong answer, and fires haptics on each result.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.horizontalSizeClass) private var hSize
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var showEndConfirm = false

    enum AnswerVisual { case idle, correct, wrong, dimmed }

    var body: some View {
        let isLandscape = vSize == .compact
        let layout = isLandscape
            ? AnyLayout(HStackLayout(spacing: 28))
            : AnyLayout(VStackLayout(spacing: 20))

        ZStack {
            VStack(spacing: 16) {
                controlBar
                progressHeader

                layout {
                    mediaCard
                    VStack(spacing: 16) {
                        feedbackBanner
                        answerGrid
                    }
                }
            }
            .padding(.vertical, 16)
            .blur(radius: viewModel.isPaused ? 10 : 0)
            .disabled(viewModel.isPaused)

            if viewModel.isPaused {
                pauseOverlay.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isPaused)
        .onAppear { playCurrentNote() }
        .onChange(of: viewModel.currentIndex) { _ in playCurrentNote() }
        .onChange(of: viewModel.feedback) { fb in
            switch fb {
            case .correct: Haptics.success()
            case .incorrect: Haptics.error()
            case .none: break
            }
        }
        .confirmationDialog("End the quiz?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Quiz", role: .destructive) { viewModel.endQuiz() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see your results so far.")
        }
    }

    // MARK: - Control bar (pause • timer • end)

    private var controlBar: some View {
        HStack {
            circleButton(icon: "pause.fill") {
                Haptics.tap()
                viewModel.pause()
            }

            Spacer()

            Label(timeString(viewModel.elapsed), systemImage: "clock.fill")
                .font(.headline.monospacedDigit())
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(.white.opacity(0.18), in: Capsule())

            Spacer()

            if viewModel.mode == .notation {
                circleButton(icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                    Haptics.tap()
                    soundEnabled.toggle()
                    if soundEnabled { playCurrentNote() }   // preview on enable
                }
            }

            circleButton(icon: "stop.fill") {
                Haptics.tap()
                showEndConfirm = true
            }
        }
    }

    /// Play the pitch of the current note. In ear-training the sound *is* the
    /// question, so it always plays; in notation mode it follows the toggle.
    private func playCurrentNote() {
        guard let question = viewModel.currentQuestion else { return }
        guard viewModel.mode == .earTraining || soundEnabled else { return }
        NotePlayer.shared.play(frequency: question.frequency)
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.18), in: Circle())
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

    private var progressFraction: Double {
        guard viewModel.total > 0 else { return 0 }
        return Double(viewModel.questionNumber) / Double(viewModel.total)
    }

    // MARK: - Prompt card (notation image or ear-training listener)

    /// Chooses the prompt for the active mode.
    @ViewBuilder
    private var mediaCard: some View {
        switch viewModel.mode {
        case .notation:     imageCard
        case .earTraining:  earCard
        }
    }

    /// Shared card chrome: fixed height, white background, rounded + shadowed,
    /// with the slide-in transition as questions advance.
    private func styledMediaCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: vSize == .compact ? 200 : 240)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
            .id(viewModel.currentIndex)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
    }

    /// The notation image plus its clef caption. Reused by both modes.
    @ViewBuilder
    private func notationImage(for question: QuizQuestion) -> some View {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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

    private var imageCard: some View {
        styledMediaCard {
            if let question = viewModel.currentQuestion {
                notationImage(for: question)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { playCurrentNote() }   // tap the notation to hear it again
    }

    /// Ear-training prompt: only a listen button — the notation is never shown,
    /// so the note has to be identified purely by ear.
    private var earCard: some View {
        styledMediaCard {
            if viewModel.currentQuestion != nil {
                listenPrompt
            }
        }
    }

    private var listenPrompt: some View {
        Button {
            playCurrentNote()
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.primary.opacity(0.12)).frame(width: 96, height: 96)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.primary)
                }
                Text("Tap to listen")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // MARK: - Pause overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                Text("Paused")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Label(timeString(viewModel.elapsed), systemImage: "clock.fill")
                    .font(.title3.monospacedDigit())
                    .foregroundColor(.white.opacity(0.9))

                VStack(spacing: 12) {
                    Button {
                        Haptics.tap()
                        viewModel.resume()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        viewModel.endQuiz()
                    } label: {
                        Text("End Quiz")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: 360)
                .padding(.top, 8)
            }
            .padding(32)
        }
    }

    // MARK: - Helpers

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
