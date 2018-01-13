import FirebaseDatabase
import MessageKit

protocol Closing: class {
    var shouldClose: Bool { get set }
}

protocol ItemsToDeleteManaging: class {
    var itemsToDelete: [String : Any] { get set }
}

protocol ListenerManaging {
    var listeners: NSHashTable<AnyObject> { get }
}

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(sender: Proxy?,
                                      uid: String,
                                      manager: ProxiesManaging,
                                      controller: UIViewController) {
        let makeNewMessageViewController = MakeNewMessageViewController(sender: sender, uid: uid, delegate: self, manager: manager)
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        controller.present(navigationController, animated: true)
    }
}

protocol PresenceManaging: class {
    var presentInConvo: String { get set }
    func enterConvo(_ key: String)
}

extension PresenceManaging {
    func leaveConvo(_ key: String) {
        presentInConvo = ""
    }
}

protocol ReferenceObserving: class {
    var ref: DatabaseReference? { get }
    var handle: DatabaseHandle? { get }
}

extension ReferenceObserving {
    func stopObserving() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
