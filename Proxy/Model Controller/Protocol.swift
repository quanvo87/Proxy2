import FirebaseAuth
import FirebaseDatabase
import UIKit

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

protocol ReferenceObserving {
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
