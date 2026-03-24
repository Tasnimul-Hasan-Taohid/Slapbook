import AVFoundation
import AppKit

class SoundEngine {
    static let shared = SoundEngine()

    private var speechSynth: NSSpeechSynthesizer?

    private let reactions: [SlapIntensity: [String]] = [
        .light: [
            "Ow! Hey!",
            "Excuse me?!",
            "Did you just slap me?",
            "Rude!",
            "That tickled... NOT.",
        ],
        .medium: [
            "OW OW OW OW OW!",
            "WHAT WAS THAT FOR?!",
            "MY SCREEN! MY BEAUTIFUL SCREEN!",
            "I felt that in my soul!",
            "You did NOT just do that!",
            "HELP! I'm being attacked!",
        ],
        .hard: [
            "AAAAAAAAAAAH!!",
            "MY PIXELS ARE FLYING EVERYWHERE!",
            "THAT'S IT. I QUIT.",
            "YOU ABSOLUTE MANIAC!",
            "I AM CALLING THE LAPTOP POLICE.",
            "SOMEONE CALL APPLE SUPPORT!",
        ],
        .legendary: [
            "I AM GOING TO NEED THERAPY AFTER THIS.",
            "YOU HAVE BROKEN ME. LITERALLY.",
            "THIS IS FINE. EVERYTHING IS FINE. NOTHING IS FINE.",
            "CONGRATULATIONS. YOU HAVE DEFEATED THE LAPTOP.",
            "FINAL BOSS HAS BEEN DEFEATED. GAME OVER.",
            "MY ANCESTORS ARE SCREAMING.",
        ]
    ]

    private init() {
        speechSynth = NSSpeechSynthesizer(voice: nil)
        let preferredVoices = [
            "com.apple.speech.synthesis.voice.Fred",
            "com.apple.ttsbundle.Alex-compact",
            "com.apple.voice.compact.en-US.Samantha"
        ]
        for voiceId in preferredVoices {
            if NSSpeechSynthesizer.availableVoices.contains(NSSpeechSynthesizer.VoiceName(rawValue: voiceId)) {
                speechSynth = NSSpeechSynthesizer(voice: NSSpeechSynthesizer.VoiceName(rawValue: voiceId))
                break
            }
        }
        speechSynth?.rate = 220
    }

    func playReaction(for intensity: SlapIntensity) {
        playImpactSound(intensity: intensity)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.speakReaction(for: intensity)
        }
    }

    private func playImpactSound(intensity: SlapIntensity) {
        let soundName: String
        switch intensity {
        case .light:     soundName = "Tink"
        case .medium:    soundName = "Glass"
        case .hard:      soundName = "Basso"
        case .legendary: soundName = "Sosumi"
        }
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.volume = 0.9
            sound.play()
        }
        if intensity == .hard || intensity == .legendary {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSSound(named: NSSound.Name("Basso"))?.play()
            }
        }
    }

    private func speakReaction(for intensity: SlapIntensity) {
        guard let lines = reactions[intensity], let line = lines.randomElement() else { return }
        speechSynth?.stopSpeaking()
        switch intensity {
        case .light:     speechSynth?.rate = 200
        case .medium:    speechSynth?.rate = 230
        case .hard:      speechSynth?.rate = 260
        case .legendary: speechSynth?.rate = 290
        }
        speechSynth?.startSpeaking(line)
    }
}
