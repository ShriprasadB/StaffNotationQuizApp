//
//  HomeView.swift
//  StaffNotationQuizApp
//
//  The single MVP home screen: a title and a Start Quiz button.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("Staff Notation Quiz")
                    .font(.largeTitle).bold()
                Text("Identify the note on the staff.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if case .error(let message) = viewModel.phase {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                Task { await viewModel.startQuiz() }
            } label: {
                Text("Start Quiz")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
