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

extension QuizQuestion {
    /// Octave parsed from the image filename embedded in `imageUrl`
    /// (e.g. ".../notations/treble_A3.png" -> 3). Falls back to 4 so a
    /// pitch can always be played.
    var octave: Int {
        let decoded = imageUrl.removingPercentEncoding ?? imageUrl
        let withoutQuery = decoded.split(separator: "?").first.map(String.init) ?? decoded
        let lastComponent = withoutQuery.split(separator: "/").last.map(String.init) ?? withoutQuery
        // lastComponent looks like "treble_A3.png"
        if let digit = lastComponent.reversed().first(where: { $0.isNumber }),
           let value = Int(String(digit)) {
            return value
        }
        return 4
    }

    /// The concert-pitch frequency (Hz) of the note shown in this question.
    var frequency: Double { correctAnswer.frequency(octave: octave) }
}

/// Top-level wrapper matching the API response shape.
struct QuizResponse: Codable {
    let questions: [QuizQuestion]
}
