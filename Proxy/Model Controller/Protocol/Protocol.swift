import FirebaseDatabase
import MessageKit
import SearchTextField

// todo: delete?
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

protocol ConvoManaging: class {
    var convo: Convo? { get set }
}

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
}

protocol FirstResponderSetting: class {
    func setFirstResponder()
}

protocol MessagesManaging: class {
    var messages: [Message] { get set }
}

protocol NewConvoManaging: class {
    var newConvo: Convo? { get set }
}

extension NewConvoManaging where Self: UIViewController {
    func showMakeNewMessageController(sender: Proxy?,
                                      uid: String) {
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
