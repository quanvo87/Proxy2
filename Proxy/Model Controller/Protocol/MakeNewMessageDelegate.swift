import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(sender: Proxy?,
                                      uid: String,
                                      manager: ProxiesManaging,
                                      controller: UIViewController) {
        guard let makeNewMessageViewController = MakeNewMessageViewController.make(sender: sender, uid: uid, delegate: self, manager: manager) else {
            return
        }
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        controller.present(navigationController, animated: true)
    }
}
