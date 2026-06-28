//
//  QuizView.swift
//  StaffNotationQuizApp
//
//  The active quiz screen: progress, the notation image, a feedback banner,
//  and the 7 fixed answer buttons (C D E F G A B).
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    var body: some View {
        VStack(spacing: 20) {
            // Progress
            Text("Question \(viewModel.questionNumber) of \(viewModel.total)")
                .font(.headline)
                .foregroundColor(.secondary)

            // Notation image
            if let question = viewModel.currentQuestion {
                AsyncImage(url: URL(string: question.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }

            // Feedback banner
            feedbackBanner
                .frame(height: 32)

            Spacer()

            // Answer buttons
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Note.allCases) { note in
                    Button {
                        viewModel.select(note)
                    } label: {
                        Text(note.rawValue)
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
            .disabled(viewModel.feedback != .none) // lock while feedback shows
            .padding(.bottom, 24)
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private var feedbackBanner: some View {
        switch viewModel.feedback {
        case .correct:
            Label("Correct", systemImage: "checkmark.circle.fill")
                .font(.title3).bold()
                .foregroundColor(.green)
        case .incorrect:
            Label("Incorrect", systemImage: "xmark.circle.fill")
                .font(.title3).bold()
                .foregroundColor(.red)
        case .none:
            EmptyView()
        }
    }
}
