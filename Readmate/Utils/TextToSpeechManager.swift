import Foundation
import AVFoundation

class TextToSpeechManager: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String) {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
        isSpeaking = true
        isPaused = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
    }
}
