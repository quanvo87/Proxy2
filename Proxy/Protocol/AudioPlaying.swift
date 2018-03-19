import AVKit

protocol AudioPlaying {
    func play()
    func playWithCooldown()
}

// todo: change to play every 5 seconds once cool sounds are in
class AudioPlayer: AudioPlaying {
    private let player: AVAudioPlayer
    private var cooldownResetItem: DispatchWorkItem?
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
        player.play()
    }

    func playWithCooldown() {
        if !onCooldown {
            onCooldown = true
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
            player.play()
        }
        cooldownResetItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.onCooldown = false
        }
        cooldownResetItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: workItem)
    }
}
