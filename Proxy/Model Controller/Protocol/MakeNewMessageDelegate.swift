import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(uid: String, sender: Proxy?, controller: UIViewController, container: DependencyContaining) {
        guard let makeNewMessageViewController = MakeNewMessageViewController.make(uid: uid, delegate: self, sender: sender, container: container) else {
            return
        }
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        controller.present(navigationController, animated: true)
    }
}
