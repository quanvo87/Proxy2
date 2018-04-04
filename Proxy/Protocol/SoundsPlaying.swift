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

// todo: warning sound?
protocol SoundsPlaying {
    func playBlock()
    func playError()
    func playMakeProxy()
    func playMessageIn()
    func playMessageOut()
    func playNewMessage()
    func playSuccess()
}

struct SoundsPlayer: SoundsPlaying {
    private let blockSoundPlayer = SoundPlayer(soundFileName: "block")
    private let errorSoundPlayer = SoundPlayer(soundFileName: "error")
    private let makeProxySoundPlayer = SoundPlayer(soundFileName: "makeProxy")
    private let messageInSoundPlayer = SoundPlayer(soundFileName: "messageIn")
    private let messageOutSoundPlayer = SoundPlayer(soundFileName: "messageOut")
    private let newMessageSoundPlayer = SoundPlayer(soundFileName: "newMessage")
    private let successSoundPlayer = SoundPlayer(soundFileName: "success")

    func playBlock() {
        blockSoundPlayer.play()
    }

    func playError() {
        errorSoundPlayer.play()
    }

    func playMakeProxy() {
        makeProxySoundPlayer.play()
    }

    func playMessageIn() {
        messageInSoundPlayer.play()
    }

    func playMessageOut() {
        messageOutSoundPlayer.play()
    }

    func playNewMessage() {
        newMessageSoundPlayer.play()
    }

    func playSuccess() {
        successSoundPlayer.play()
    }
}
