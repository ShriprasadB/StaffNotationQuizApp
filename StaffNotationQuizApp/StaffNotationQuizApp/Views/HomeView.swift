//
//  HomeView.swift
//  StaffNotationQuizApp
//
//  Landing screen: animated hero + Start button, on the brand gradient.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulse ? 1.08 : 0.92)
                Image(systemName: "music.note")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 10) {
                Text("Staff Notation Quiz")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Read the note on the staff and pick the right letter.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            if case .error(let message) = viewModel.phase {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding()
                    .background(Theme.incorrect.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                Haptics.tap()
                Task { await viewModel.startQuiz() }
            } label: {
                Label("Start Quiz", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 12)
        }
        .frame(maxWidth: 480)
        .padding(.vertical, 24)
    }
}
