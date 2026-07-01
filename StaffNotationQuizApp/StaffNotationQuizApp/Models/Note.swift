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

    /// Semitones above C within an octave (C=0, D=2, … B=11).
    var semitonesFromC: Int {
        switch self {
        case .c: return 0
        case .d: return 2
        case .e: return 4
        case .f: return 5
        case .g: return 7
        case .a: return 9
        case .b: return 11
        }
    }

    /// Concert-pitch frequency (Hz) for this note in the given octave,
    /// using A4 = 440 Hz equal temperament.
    func frequency(octave: Int) -> Double {
        let midi = (octave + 1) * 12 + semitonesFromC
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
}
