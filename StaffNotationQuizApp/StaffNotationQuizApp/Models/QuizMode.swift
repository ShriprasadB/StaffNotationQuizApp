//
//  QuizMode.swift
//  StaffNotationQuizApp
//
//  The kinds of quiz the user can choose from on the home screen.
//  Both use the same 34 notes; they differ in what the prompt shows.
//

import Foundation

enum QuizMode: String, CaseIterable, Identifiable {
    /// See the notation, name the note.
    case notation
    /// Hear the pitch, name the note.
    case earTraining

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notation: return "Notation Quiz"
        case .earTraining: return "Ear Training"
        }
    }

    var subtitle: String {
        switch self {
        case .notation: return "See the note, name it"
        case .earTraining: return "Hear the note, name it"
        }
    }

    var icon: String {
        switch self {
        case .notation: return "music.note"
        case .earTraining: return "ear.fill"
        }
    }
}
