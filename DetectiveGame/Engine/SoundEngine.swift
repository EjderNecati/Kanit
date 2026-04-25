import AVFoundation
import SwiftUI

/// Prosedural ses motoru - web'deki AudioContext karsiligidir
/// Tum sesler AVAudioEngine ile kodda uretilir, ses dosyasi gerekmez
class SoundEngine {
    static let shared = SoundEngine()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var ambientPlayer: AVAudioPlayerNode?
    private let sampleRate: Double = 44100.0
    private var isEnabled: Bool = true

    private init() {
        setupAudioSession()
        setupEngine()
    }

    // MARK: - Kurulum

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("SoundEngine: Audio session kurulum hatasi: \(error)")
        }
    }

    private func setupEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        ambientPlayer = AVAudioPlayerNode()

        guard let engine = audioEngine,
              let player = playerNode,
              let ambient = ambientPlayer else { return }

        engine.attach(player)
        engine.attach(ambient)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.connect(ambient, to: engine.mainMixerNode, format: format)

        // Ambient sesi daha kisik
        ambient.volume = 0.15

        do {
            try engine.start()
        } catch {
            print("SoundEngine: Engine baslatilamadi: \(error)")
        }
    }

    // MARK: - Kontrol

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopAmbient()
        }
    }

    // MARK: - Ses Efektleri

    /// Daktilo tiklamasi - TypewriterText'te her harf icin
    func typeClick() {
        guard isEnabled else { return }
        playTone(frequency: 800 + Double.random(in: -100...100),
                 duration: 0.015,
                 volume: 0.04,
                 decay: 0.8)
    }

    /// Secenek tiklama sesi
    func choiceSelect() {
        guard isEnabled else { return }
        playTone(frequency: 440, duration: 0.08, volume: 0.12, decay: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.playTone(frequency: 554, duration: 0.06, volume: 0.08, decay: 0.5)
        }
    }

    /// Delil toplama - cingirdak sesi
    func evidenceChime() {
        guard isEnabled else { return }
        let notes: [(Double, Double)] = [(880, 0.0), (1047, 0.08), (1319, 0.16)]
        for (freq, delay) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.15, volume: 0.1, decay: 0.4)
            }
        }
    }

    /// Sahne gecis sesi - yumusak fade
    func sceneTransition() {
        guard isEnabled else { return }
        playTone(frequency: 220, duration: 0.3, volume: 0.06, decay: 0.2)
    }

    /// Suclama sahnesi - davul/darbuka
    func accusationDrum() {
        guard isEnabled else { return }
        playTone(frequency: 100, duration: 0.2, volume: 0.15, decay: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.playTone(frequency: 80, duration: 0.3, volume: 0.2, decay: 0.6)
        }
    }

    /// Basarim fanfari
    func achievementFanfare() {
        guard isEnabled else { return }
        let fanfare: [(Double, Double)] = [
            (523, 0.0), (659, 0.1), (784, 0.2), (1047, 0.35)
        ]
        for (freq, delay) in fanfare {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.2, volume: 0.12, decay: 0.3)
            }
        }
    }

    /// Capraz referans - baglanti sesi
    func crossRefSound() {
        guard isEnabled else { return }
        playTone(frequency: 660, duration: 0.12, volume: 0.08, decay: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.playTone(frequency: 880, duration: 0.1, volume: 0.06, decay: 0.4)
        }
    }

    /// Mikro ifade yakalama
    func expressionCatch() {
        guard isEnabled else { return }
        playTone(frequency: 1200, duration: 0.05, volume: 0.1, decay: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.playTone(frequency: 1500, duration: 0.04, volume: 0.08, decay: 0.6)
        }
    }

    // MARK: - Ambient Ortam Sesi

    func playAmbientMood(_ mood: String) {
        guard isEnabled else { return }
        // Ambient sesi durdur ve yeni mood baslasin
        // Prosedural ambient icin basta sessiz bir ton, sonra fade-in
        stopAmbient()

        let frequency: Double
        switch mood {
        case "night": frequency = 80
        case "warm": frequency = 120
        case "cold": frequency = 100
        case "tense": frequency = 60
        default: frequency = 90
        }

        // Cok kisik drone sesi
        playAmbientDrone(frequency: frequency, duration: 10)
    }

    func stopAmbient() {
        ambientPlayer?.stop()
    }

    // MARK: - Karakter Motifi

    func suspectMotif(_ characterId: String) {
        guard isEnabled else { return }
        // Her karakter icin farkli kisa motif
        let hash = characterId.hash
        let baseNote = 220.0 + Double(abs(hash) % 200)
        playTone(frequency: baseNote, duration: 0.15, volume: 0.06, decay: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.playTone(frequency: baseNote * 1.25, duration: 0.12, volume: 0.04, decay: 0.3)
        }
    }

    // MARK: - Dahili Ses Uretimi

    private func playTone(frequency: Double, duration: Double, volume: Float, decay: Double) {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * decay / duration))
            let sample = Float(sin(2.0 * .pi * frequency * t)) * volume * envelope
            data[i] = sample
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    private func playAmbientDrone(frequency: Double, duration: Double) {
        guard let player = ambientPlayer, let engine = audioEngine, engine.isRunning else { return }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Hafif LFO ile canlilastir
            let lfo = 1.0 + 0.1 * sin(2.0 * .pi * 0.5 * t)
            let sample = Float(sin(2.0 * .pi * frequency * lfo * t)) * 0.03
            data[i] = sample
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
}
