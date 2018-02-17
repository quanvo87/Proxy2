import FirebaseDatabase
import UIKit

protocol NewMessageMakerDelegate: class {
    var newConvo: Convo? { get set }
}

extension NewMessageMakerDelegate where Self: UIViewController {
    func showNewMessageMakerViewController(sender: Proxy?, uid: String) {
        let makeNewMessageViewController = NewMessageMakerViewController(sender: sender,
                                                                         uid: uid,
                                                                         newMessageMakerDelegate: self)
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

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
