//
//  ResultsView.swift
//  StaffNotationQuizApp
//
//  End-of-quiz stats: time taken, score, and accuracy. (Persisting these to
//  the backend is future scope; for now they are computed in the view model.)
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Quiz Complete")
                .font(.largeTitle).bold()

            VStack(spacing: 16) {
                statRow(title: "Score", value: "\(viewModel.score) / \(viewModel.total)")
                statRow(title: "Accuracy", value: String(format: "%.0f%%", viewModel.accuracy))
                statRow(title: "Time", value: formattedTime(viewModel.elapsed))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button {
                Task { await viewModel.startQuiz() }
            } label: {
                Text("Play Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Button("Back to Home") {
                viewModel.reset()
            }
            .padding(.bottom, 24)
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
