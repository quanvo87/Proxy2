//
//  LogInAVPlayer.swift
//  proxy
//
//  Created by Quan Vo on 6/5/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import AVFoundation

class LogInVideoPlayer {
    private let player: AVPlayer

    init?(view: UIView) {
        let videos = ["arabiangulf", "beachpalm", "dragontailzipline", "hawaiiancoast"]
        let rand = Int(arc4random_uniform(UInt32(videos.count)))

        guard let path = Bundle.main.path(forResource: "/Splash Videos/\(videos[rand])", ofType: "mp4") else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        player.isMuted = true

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.frame
        playerLayer.opacity = 0.95
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.zPosition = -1
        view.layer.addSublayer(playerLayer)

        player.play()

        NotificationCenter.default.addObserver(self, selector: #selector(LogInVideoPlayer.loopVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private dynamic func loopVideo() {
        player.seek(to: kCMTimeZero)
        player.play()
    }
}
