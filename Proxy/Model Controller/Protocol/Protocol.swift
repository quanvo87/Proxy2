import FirebaseDatabase
import MessageKit

// todo: delete?
protocol ButtonAnimating: class {
    func animateButton()
    func stopAnimatingButton()
}

protocol Closing: class {
    var shouldClose: Bool { get set }
}

protocol ItemsToDeleteManaging: class {
    var itemsToDelete: [String : Any] { get set }
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
