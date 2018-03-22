import AVKit

protocol AudioPlaying {
    func play()
}

class AudioPlayer: AudioPlaying {
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
        guard UserDefaults.standard.bool(forKey: Constant.soundOn) else {
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
