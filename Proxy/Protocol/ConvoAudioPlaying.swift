protocol ConvoAudioPlaying {
    func playIncomingMessageSound()
    func playOutgoingMessageSound()
}

struct ConvoAudioPlayer: ConvoAudioPlaying {
    private let incomingMessageAudioPlayer = AudioPlayer(soundFileName: "textIn")
    private let outgoingMessageAudioPlayer = AudioPlayer(soundFileName: "textOut")

    func playIncomingMessageSound() {
        incomingMessageAudioPlayer.playWithCooldown()
    }

    func playOutgoingMessageSound() {
        outgoingMessageAudioPlayer.playWithCooldown()
    }
}
