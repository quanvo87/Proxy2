import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(uid: String, sender: Proxy?, viewController: UIViewController?) {
        guard let makeNewMessageViewController = MakeNewMessageViewController.make(uid: uid, delegate: self, sender: sender) else {
            return
        }
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        viewController?.present(navigationController, animated: true)
    }
}
