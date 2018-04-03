import AVKit

private protocol SoundPlaying {
    func play()
}

private class SoundPlayer: SoundPlaying {
    private let player: AVAudioPlayer

    init(soundFileName: String, fileTypeHint: String = "wav") {
        let dataAsset = NSDataAsset(name: soundFileName)
        do {
            guard let data = dataAsset?.data else {
                throw ProxyError.unknown
            }
            player = try AVAudioPlayer(data: data, fileTypeHint: fileTypeHint)
        } catch {
            player = AVAudioPlayer()
        }
    }

    func play() {
        guard UserDefaults.standard.bool(forKey: SettableUserProperty.Name.soundOn.rawValue) else {
            return
        }
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryAmbient,
                mode: AVAudioSessionModeDefault
            )
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        player.play()
    }
}

protocol SoundsPlaying {
    func playBlock()
    func playError()
    func playIncomingMessage()
    func playMakeProxy()
    func playNewMessage()
    func playOutgoingMessage()
    func playSuccess()
    func playWarning()
}

struct SoundsPlayer: SoundsPlaying {
    private let blockSoundPlayer = SoundPlayer(soundFileName: "block")
    private let errorSoundPlayer = SoundPlayer(soundFileName: "error")
    private let incomingMessageSoundPlayer = SoundPlayer(soundFileName: "incomingMessage")
    private let makeProxySoundPlayer = SoundPlayer(soundFileName: "makeProxy")
    private let newMessageSoundPlayer = SoundPlayer(soundFileName: "newMessage")
    private let outgoingMessageSoundPlayer = SoundPlayer(soundFileName: "incomingMessage")
    private let successSoundPlayer = SoundPlayer(soundFileName: "success")
    private let warningSoundPlayer = SoundPlayer(soundFileName: "warning")

    func playBlock() {
        blockSoundPlayer.play()
    }

    func playError() {
        errorSoundPlayer.play()
    }

    func playIncomingMessage() {
        incomingMessageSoundPlayer.play()
    }

    func playMakeProxy() {
        makeProxySoundPlayer.play()
    }

    func playNewMessage() {
        newMessageSoundPlayer.play()
    }

    func playOutgoingMessage() {
        outgoingMessageSoundPlayer.play()
    }

    func playSuccess() {
        successSoundPlayer.play()
    }

    func playWarning() {
        warningSoundPlayer.play()
    }
}
