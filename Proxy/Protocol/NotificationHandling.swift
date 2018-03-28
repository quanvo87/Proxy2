import Foundation

protocol NotificationHandling {
    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
    func showNewMessageBanner(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
}

class NotificationHandler: NotificationHandling {
    private let convoPresenceObserver = ConvoPresenceObserver()

    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey, convoKey != convoPresenceObserver.currentConvoKey else {
            completion()
            return
        }
        Shared.database.getConvo(convoKey: convoKey, ownerId: uid) { result in
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
        Shared.database.getConvo(convoKey: convoKey, ownerId: uid) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                Audio.incomingMessageAudioPlayer.play()
                StatusBar.showNewMessageBanner(convo)
            }
            completion()
        }
    }
}
