//
//  Note.swift
//  StaffNotationQuizApp
//
//  The 7 possible answers. These are also the 7 fixed buttons shown in the quiz.
//

import Foundation

enum Note: String, CaseIterable, Codable, Identifiable {
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case a = "A"
    case b = "B"

    var id: String { rawValue }
}
