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
                Text("Pick a quiz, then name the notes.")
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

            VStack(spacing: 14) {
                ForEach(QuizMode.allCases) { mode in
                    modeButton(mode)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: 480)
        .padding(.vertical, 24)
    }

    private func modeButton(_ mode: QuizMode) -> some View {
        Button {
            Haptics.tap()
            Task { await viewModel.startQuiz(mode: mode) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(Theme.primary.opacity(0.15), in: Circle())
                    .foregroundColor(Theme.primaryDark)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title).font(.headline)
                    Text(mode.subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(Theme.primaryDark)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
    }
}
