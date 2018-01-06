import UIKit

protocol UnreadMessagesManaging: class {
    var unreadMessages: [Message] { get set }
    func load(uid: String,
              controller: UIViewController,
              presenceManager: PresenceManaging,
              proxiesManager: ProxiesManaging)
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
    private weak var controller: UIViewController?

    func load(uid: String,
              controller: UIViewController,
              presenceManager: PresenceManaging,
              proxiesManager: ProxiesManaging) {
        self.controller = controller
        unreadMessageAddedObserver.observe(uid: uid,
                                           presenceManager: presenceManager,
                                           proxiesManager: proxiesManager,
                                           unreadMessagesManager: self)
        unreadMessageRemovedObserver.observe(uid: uid, manager: self)
    }
}
