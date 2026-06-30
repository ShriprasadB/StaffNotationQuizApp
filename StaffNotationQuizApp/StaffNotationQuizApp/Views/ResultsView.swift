//
//  ResultsView.swift
//  StaffNotationQuizApp
//
//  End-of-quiz summary: an animated accuracy ring plus score and time cards.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var animateRing = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "rosette")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
                Text("Quiz Complete")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }

            accuracyRing

            HStack(spacing: 14) {
                statCard(title: "Score",
                         value: "\(viewModel.score)/\(viewModel.total)",
                         icon: "star.fill")
                statCard(title: "Time",
                         value: formattedTime(viewModel.elapsed),
                         icon: "clock.fill")
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    Task { await viewModel.startQuiz() }
                } label: {
                    Label("Play Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    viewModel.reset()
                } label: {
                    Text("Back to Home")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: 480)
        .padding(.vertical, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { animateRing = true }
        }
    }

    private var accuracyRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 16)
            Circle()
                .trim(from: 0, to: animateRing ? viewModel.accuracy / 100 : 0)
                .stroke(Theme.correct,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(String(format: "%.0f%%", viewModel.accuracy))
                    .font(.system(size: 46, weight: .bold))
                Text("Accuracy")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
        }
        .frame(width: 200, height: 200)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(Theme.primary)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .card()
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
