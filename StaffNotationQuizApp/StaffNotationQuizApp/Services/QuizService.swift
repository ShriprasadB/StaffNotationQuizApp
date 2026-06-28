//
//  QuizService.swift
//  StaffNotationQuizApp
//
//  Data source for quiz questions. The app talks to this protocol only, so we
//  can swap MockQuizService for a real FirebaseQuizService later without
//  touching the UI or the view model.
//

import Foundation

protocol QuizService {
    func fetchQuestions() async throws -> [QuizQuestion]
}

enum QuizServiceError: LocalizedError {
    case missingResource

    var errorDescription: String? {
        switch self {
        case .missingResource: return "Could not find quiz_mock.json in the app bundle."
        }
    }
}

/// MVP data source: loads questions from a bundled JSON file that has the exact
/// same shape as the future backend response.
final class MockQuizService: QuizService {
    func fetchQuestions() async throws -> [QuizQuestion] {
        guard let url = Bundle.main.url(forResource: "quiz_mock", withExtension: "json") else {
            throw QuizServiceError.missingResource
        }
        let data = try Data(contentsOf: url)
        let response = try JSONDecoder().decode(QuizResponse.self, from: data)
        return response.questions
    }
}
