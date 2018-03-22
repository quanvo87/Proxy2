import Foundation

protocol NotificationHandling {
    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
    func showNewMessageBanner(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
}

class NotificationHandler: NotificationHandling {
    private let convoPresenceObserver: ConvoPresenceObserving
    private let database: Database
    private let incomingMessageAudioPlayer: AudioPlaying

    init(convoPresenceObserver: ConvoPresenceObserving = ConvoPresenceObserver(),
         database: Database = Constant.database,
         incomingMessageAudioPlayer: AudioPlaying = Audio.incomingMessageAudioPlayer) {
        self.convoPresenceObserver = convoPresenceObserver
        self.database = database
        self.incomingMessageAudioPlayer = incomingMessageAudioPlayer
    }

    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey, convoKey != convoPresenceObserver.currentConvoKey else {
            completion()
            return
        }
        database.getConvo(convoKey: convoKey, ownerId: uid) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                NotificationCenter.default.post(
                    name: .shouldShowConvo,
                    object: nil,
                    userInfo: ["convo": convo]
                )
            }
            completion()
        }
    }

    func showNewMessageBanner(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        if convoPresenceObserver.currentConvoKey == String(describing: ConvosViewController.self) {
            completion()
            return
        }
        guard let convoKey = userInfo.parentConvoKey, convoKey != convoPresenceObserver.currentConvoKey else {
            completion()
            return
        }
        database.getConvo(convoKey: convoKey, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                self?.incomingMessageAudioPlayer.play()
                StatusBar.showNewMessageBanner(convo)
            }
            completion()
        }
    }
}
