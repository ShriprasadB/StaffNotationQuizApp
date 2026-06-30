//
//  FirebaseQuizService.swift
//  StaffNotationQuizApp
//
//  Real data source: reads quiz questions from the Firestore `questions`
//  collection. Each document stores { imageUrl, correctAnswer, clef }.
//  Conforms to QuizService, so it drops in for MockQuizService with no UI changes.
//

import Foundation
import FirebaseFirestore

final class FirebaseQuizService: QuizService {
    private let db = Firestore.firestore()

    func fetchQuestions() async throws -> [QuizQuestion] {
        let snapshot = try await db.collection("questions").getDocuments()

        let questions: [QuizQuestion] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard
                let imageUrl = data["imageUrl"] as? String,
                let answerRaw = data["correctAnswer"] as? String,
                let answer = Note(rawValue: answerRaw)
            else { return nil }

            return QuizQuestion(id: doc.documentID, imageUrl: imageUrl, correctAnswer: answer)
        }

        // Randomize order each run; each question appears once.
        return questions.shuffled()
    }
}
