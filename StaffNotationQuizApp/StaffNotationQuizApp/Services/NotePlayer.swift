//
//  NotePlayer.swift
//  StaffNotationQuizApp
//
//  Synthesizes and plays the pitch of a note so the learner can hear what the
//  notation on screen sounds like. Tones are generated on the fly (fundamental
//  plus a couple of harmonics with a soft envelope) — no audio files needed.
//

import AVFoundation

final class NotePlayer {
    static let shared = NotePlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat
    private var isConfigured = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    /// Play a single note at the given frequency (Hz).
    /// Any note already sounding is cut off so notes never pile up.
    func play(frequency: Double, duration: Double = 1.4) {
        guard frequency > 0 else { return }
        configureIfNeeded()

        guard let buffer = makeBuffer(frequency: frequency, duration: duration) else { return }

        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }

        player.stop()   // interrupt whatever was playing
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    // MARK: - Setup

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    // MARK: - Tone generation

    private func makeBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard
            frameCount > 0,
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return nil }

        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]
        let count = Int(frameCount)

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Fundamental plus quieter harmonics for a warmer, less buzzy tone.
            var value = sin(2 * .pi * frequency * t)
            value += 0.50 * sin(2 * .pi * frequency * 2 * t)
            value += 0.25 * sin(2 * .pi * frequency * 3 * t)
            value /= 1.75

            // Envelope: fast attack, gentle decay so it fades out cleanly.
            let progress = Double(i) / Double(count)
            let attack = min(1.0, t / 0.01)
            let decay = pow(1.0 - progress, 1.5)

            samples[i] = Float(value * attack * decay * 0.35)
        }

        return buffer
    }
}
