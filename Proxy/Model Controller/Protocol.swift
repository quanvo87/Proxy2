import FirebaseDatabase
import UIKit

protocol ConvoManaging: class {
    var convo: Convo? { get set }
}

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
}

protocol MessagesManaging: class {
    var messages: [Message] { get set }
}

protocol NewConvoManaging: class {
    var newConvo: Convo? { get set }
}

extension NewConvoManaging where Self: UIViewController {
    func showMakeNewMessageController(sender: Proxy?, uid: String) {
        let makeNewMessageViewController = MakeNewMessageViewController(sender: sender,
                                                                        uid: uid,
                                                                        newConvoManager: self)
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        present(navigationController, animated: true)
    }
}

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
}

protocol ProxyManaging: class {
    var proxy: Proxy? { get set }
}

// todo: is class bound necessary?
protocol ReferenceObserving: class {
    var handle: DatabaseHandle? { get }
    var ref: DatabaseReference? { get }
}

extension ReferenceObserving {
    func stopObserving() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

protocol SenderManaging: class {
    var sender: Proxy? { get set }
}

protocol UnreadMessagesManaging: class {
    func unreadMessageAdded(_ message: Message)
    func unreadMessageRemoved(_ message: Message)
}

protocol UserStatsManaging: class {
    var messagesReceivedCount: String { get set }
    var messagesSentCount: String { get set }
    var proxiesInteractedWithCount: String { get set }
}
