//
//  QuizQuestion.swift
//  StaffNotationQuizApp
//
//  Mirrors the JSON returned by the backend:
//  { "questions": [ { "id", "imageUrl", "correctAnswer" } ] }
//

import Foundation

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let correctAnswer: Note
    let clef: String?          // "treble" | "bass" — for a caption; optional
}

/// Top-level wrapper matching the API response shape.
struct QuizResponse: Codable {
    let questions: [QuizQuestion]
}
