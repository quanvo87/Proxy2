import UIKit

class ConvosButtonManager {
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private var uid: String?
    private weak var controller: UIViewController?
    private weak var delegate: MakeNewMessageDelegate?
    private weak var manager: ProxiesManaging?

    func load(uid: String,
              controller: UIViewController,
              delegate: MakeNewMessageDelegate,
              manager: ProxiesManaging) {
        self.uid = uid
        self.controller = controller
        self.delegate = delegate
        self.manager = manager
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
        controller.navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
    }
}

extension ConvosButtonManager: ButtonAnimating {
    func animateButton() {
        makeNewMessageButton.morph(loop: true)
    }

    func stopAnimatingButton() {
        makeNewMessageButton.stopAnimating()
    }
}

private extension ConvosButtonManager {
    @objc func makeNewProxy() {
        guard
            let uid = uid,
            let proxyCount = manager?.proxies.count else {
                return
        }
        makeNewProxyButton.morph()
        makeNewProxyButton.isEnabled = false
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.controller?.showAlert(title: "Error Creating Proxy", message: error.description)
            case .success:
                guard
                    let proxiesNavigationController = self?.controller?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
            }
            self?.controller?.tabBarController?.selectedIndex = 1
            self?.makeNewProxyButton.isEnabled = true
        }
    }

    @objc func showMakeNewMessageController() {
        guard
            let uid = uid,
            let controller = controller,
            let manager = manager else {
                return
        }
        makeNewMessageButton.morph()
        makeNewMessageButton.isEnabled = false
        delegate?.showMakeNewMessageController(sender: nil, uid: uid, manager: manager, controller: controller)
        makeNewMessageButton.isEnabled = true
    }
}
