import Foundation

protocol NotificationHandling {
    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
    func showNewMessageBanner(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void)
}

struct NotificationHandler: NotificationHandling {
    private let database: Database
    private weak var convoPresenceObserver: ConvoPresenceObserving?

    init(database: Database = Firebase(), convoPresenceObserver: ConvoPresenceObserving) {
        self.database = database
        self.convoPresenceObserver = convoPresenceObserver
    }

    func sendShouldShowConvoNotification(uid: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey, convoKey != convoPresenceObserver?.currentConvoKey else {
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
        guard let convoKey = userInfo.parentConvoKey, convoKey != convoPresenceObserver?.currentConvoKey else {
            completion()
            return
        }
        database.getConvo(convoKey: convoKey, ownerId: uid) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                StatusBar.showNewMessageBanner(convo)
            }
            completion()
        }
    }
}
