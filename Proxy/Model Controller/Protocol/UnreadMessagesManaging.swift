import UIKit

protocol UnreadMessagesManaging: class {
    var unreadMessages: [Message] { get set }
    func load(uid: String, controller: UIViewController, container: DependencyContaining)
    func enterConvo(_ convoKey: String)
    func leaveConvo(_ convoKey: String)
}

class UnreadMessagesManager: UnreadMessagesManaging {
    var unreadMessages = [Message]() {
        didSet {
            let count = unreadMessages.count
            if count == 0 {
                controller?.navigationItem.title = "Messages"
                controller?.tabBarController?.tabBar.items?.first?.badgeValue = nil
            } else {
                controller?.navigationItem.title = "Messages" + count.asStringWithParens
                controller?.tabBarController?.tabBar.items?.first?.badgeValue = count == 0 ? nil : String(count)
            }
        }
    }

    private let unreadMessageAddedObserver = UnreadMessageAddedObserver()
    private let unreadMessageRemovedObserver = UnreadMessageRemovedObserver()
    private weak var presenceManager: PresenceManaging?
    private weak var controller: UIViewController?

    func load(uid: String, controller: UIViewController, container: DependencyContaining) {
        self.presenceManager = container.presenceManager
        self.controller = controller
        unreadMessageAddedObserver.observe(uid: uid, container: container)
        unreadMessageRemovedObserver.observe(uid: uid, manager: self)
    }

    func enterConvo(_ convoKey: String) {
        presenceManager?.presentInConvo = convoKey
        var untouchedMessages = [Message]()
        for message in unreadMessages {
            if message.parentConvoKey == convoKey {
                DB.read(message) { _ in }
            } else {
                untouchedMessages.append(message)
            }
        }
        unreadMessages = untouchedMessages
    }

    func leaveConvo(_ convoKey: String) {
        presenceManager?.presentInConvo = ""
    }
}
