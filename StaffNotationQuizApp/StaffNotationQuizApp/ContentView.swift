//
//  ContentView.swift
//  StaffNotationQuizApp
//
//  Root coordinator. Owns the QuizViewModel, paints the brand background, and
//  shows the right screen for the current phase with an animated transition.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            content
                .frame(maxWidth: 700)          // keep content readable on iPad
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
        }
        .animation(.easeInOut(duration: 0.35), value: phaseID)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .error:
            HomeView(viewModel: viewModel)
                .transition(.opacity)
        case .loading:
            ProgressView()
                .controlSize(.large)
                .tint(.white)
                .transition(.opacity)
        case .active:
            QuizView(viewModel: viewModel)
                .transition(.opacity)
        case .finished:
            ResultsView(viewModel: viewModel)
                .transition(.opacity)
        }
    }

    private var phaseID: Int {
        switch viewModel.phase {
        case .idle: return 0
        case .loading: return 1
        case .active: return 2
        case .finished: return 3
        case .error: return 4
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
