import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(sender: Proxy?,
                                      uid: String,
                                      proxiesManager: ProxiesManaging,
                                      proxyKeysManager: ProxyKeysManaging,
                                      controller: UIViewController) {
        guard let makeNewMessageViewController = MakeNewMessageViewController.make(sender: sender, uid: uid, delegate: self, proxiesManager: proxiesManager, proxyKeysManager: proxyKeysManager) else {
            return
        }
        let navigationController = UINavigationController(rootViewController: makeNewMessageViewController)
        controller.present(navigationController, animated: true)
    }
}
