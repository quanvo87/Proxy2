import FirebaseDatabase
import MessageKit
import SearchTextField

protocol ButtonManaging: class {
    func animateButton()
    func stopAnimatingButton()
    func setButtons(_ isEnabled: Bool)
}

extension ButtonManaging {
    func animateButton() {}
    func stopAnimatingButton() {}
    func setButtons(_ isEnabled: Bool) {}
}

protocol Closing: class {
    var shouldClose: Bool { get set }
}

protocol FirstResponderSetting: class {
    func setFirstResponder()
}

protocol ItemsToDeleteManaging: class {
    var itemsToDelete: [String: Any] { get set }
}

protocol NewConvoManaging: class {
    var newConvo: Convo? { get set }
}

extension NewConvoManaging {
    func showMakeNewMessageController(sender: Proxy?,
                                      uid: String,
                                      manager: ProxiesManaging?,
                                      controller: UIViewController?) {
        let makeNewMessageViewController = MakeNewMessageViewController(sender: sender,
                                                                        uid: uid,
                                                                        newConvoManager: self,
                                                                        proxiesManager: manager)
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        controller?.present(navigationController, animated: true)
    }
}

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

protocol StoryboardMakable {
    static var identifier: String { get }
}

extension StoryboardMakable {
    static func make() -> Self? {
        guard let controller = UIStoryboard.main.instantiateViewController(withIdentifier: identifier) as? Self else {
            return nil
        }
        return controller
    }
}