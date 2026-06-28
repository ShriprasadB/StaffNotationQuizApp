//
//  ContentView.swift
//  StaffNotationQuizApp
//
//  Root coordinator. Owns the QuizViewModel and shows the right screen for the
//  current quiz phase.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()

    var body: some View {
        switch viewModel.phase {
        case .idle, .error:
            HomeView(viewModel: viewModel)
        case .loading:
            ProgressView("Loading quiz…")
        case .active:
            QuizView(viewModel: viewModel)
        case .finished:
            ResultsView(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
