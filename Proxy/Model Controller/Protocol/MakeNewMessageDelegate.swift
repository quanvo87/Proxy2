import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(controller: UIViewController?, sender: Proxy?, uid: String) {
        guard let viewController = MakeNewMessageViewController.make(delegate: self, sender: sender, uid: uid) else { return }
        let navigationController = UINavigationController(rootViewController: viewController)
        controller?.present(navigationController, animated: true)
    }
}
