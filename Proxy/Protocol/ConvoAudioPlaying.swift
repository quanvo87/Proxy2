import AVKit

protocol ConvoAudioPlaying {
    func playIncomingMessageSound()
    func playOutgoingMessageSound()
}

class ConvoAudioPlayer: ConvoAudioPlaying {
    private let incomingMessageSoundPlayer: AudioPlayer
    private let outgoingMessageSoundPlayer: AudioPlayer

    init() {
        incomingMessageSoundPlayer = AudioPlayer(soundFileName: "textIn")
        outgoingMessageSoundPlayer = AudioPlayer(soundFileName: "textOut")
    }

    func playIncomingMessageSound() {
        incomingMessageSoundPlayer.play()
    }

    func playOutgoingMessageSound() {
        outgoingMessageSoundPlayer.play()
    }
}
