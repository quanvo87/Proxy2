import AVKit

protocol AudioPlaying {
    func playSound(name: String, fileType: String) throws
}

class AudioPlayer: AudioPlaying {
    private lazy var player = AVAudioPlayer()

    func playSound(name: String, fileType: String) throws {
        let asset = NSDataAsset(name: name)
        guard let data = asset?.data else {
            throw ProxyError.unknown
        }
        player = try AVAudioPlayer(data: data, fileTypeHint: fileType)
        if #available(iOS 10.0, *) {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryAmbient
            )
        }
        player.play()
    }
}
