import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(sender: Proxy?, uid: String, viewController: UIViewController?) {
        guard let makeNewMessageViewController = MakeNewMessageViewController.make(delegate: self, sender: sender, uid: uid) else {
            return
        }
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        viewController?.present(navigationController, animated: true)
    }
}
