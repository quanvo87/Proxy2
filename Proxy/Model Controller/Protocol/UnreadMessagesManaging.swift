import FirebaseDatabase
import UIKit

protocol UnreadMessagesManaging: class {
    var unreadMessages: [Message] { get set }
    func setController(_ controller: UIViewController)
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
    private let ref: DatabaseReference?
    private var addedHandle: DatabaseHandle?
    private var removedHandle: DatabaseHandle?
    private weak var controller: UIViewController?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?

    init(_ uid: String) {
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        addedHandle = ref?.observe(.childAdded) { [weak self] (data) in
            guard
                let _self = self,
                let proxiesManager = _self.proxiesManager else {
                    return
            }
            guard let message = Message(data) else {
                return
            }
            guard proxiesManager.proxies.contains(where: { $0.key == message.receiverProxyKey }) else {
                DB.deleteUnreadMessage(message) { _ in }
                return
            }
            if _self.presenceManager?.presentInConvo == message.parentConvoKey {
                DB.read(message) { _ in }
            } else {
                _self.unreadMessages.append(message)
            }
        }
        removedHandle = ref?.observe(.childRemoved) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard
                let message = Message(data),
                let index = _self.unreadMessages.index(of: message) else {
                    return
            }
            _self.unreadMessages.remove(at: index)
        }
    }

    func setController(_ controller: UIViewController) {
        self.controller = controller
    }

    func load(presenceManager: PresenceManaging?, proxiesManager: ProxiesManaging?) {
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
    }

    deinit {
        if let addedHandle = addedHandle {
            ref?.removeObserver(withHandle: addedHandle)
        }
        if let removedHandle = removedHandle {
            ref?.removeObserver(withHandle: removedHandle)
        }
    }
}
