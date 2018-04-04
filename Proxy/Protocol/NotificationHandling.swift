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
        Firebase.getConvo(ownerId: uid, convoKey: convoKey) { result in
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
        Firebase.getConvo(ownerId: uid, convoKey: convoKey) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                Sound.soundsPlayer.playNewMessage()
                StatusBar.showNewMessageBanner(convo)
            }
            completion()
        }
    }
}
