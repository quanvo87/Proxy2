import AVKit

protocol AudioPlaying {
    func play()
    func playWithCooldown()
}

// todo: .
class AudioPlayer: AudioPlaying {
    private let player: AVAudioPlayer
    private var onCooldown = false

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
        guard UserSetting.soundOn else {
            return
        }
        player.play()
    }

    func playWithCooldown() {
        guard UserSetting.soundOn else {
            return
        }
        if !onCooldown {
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
            player.play()
            onCooldown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
                self?.onCooldown = false
            }
        }
    }
}
