import Foundation

protocol NotificationHandling {
    func sendShouldShowConvoNotification(uid: String?, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
    func showNewMessageBanner(uid: String?, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
}

class NotificationHandler: NotificationHandling {
    private let database = Firebase()
    private let incomingMessageAudioPlayer = AudioPlayer(soundFileName: "textIn")
    private weak var convoPresenceObserver: ConvoPresenceObserving?

    init(convoPresenceObserver: ConvoPresenceObserving) {
        self.convoPresenceObserver = convoPresenceObserver
    }

    func sendShouldShowConvoNotification(uid: String?, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey,
            convoKey != convoPresenceObserver?.currentConvoKey,
            let uid = uid else {
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

    func showNewMessageBanner(uid: String?, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey,
            convoKey != convoPresenceObserver?.currentConvoKey,
            let uid = uid else {
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
