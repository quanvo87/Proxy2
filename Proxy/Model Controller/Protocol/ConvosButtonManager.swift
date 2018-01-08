import UIKit
import ViewGlower

class ConvosButtonManager: ButtonManaging {
    let viewGlower = ViewGlower()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private var uid: String?
    private weak var controller: UIViewController?
    private weak var delegate: MakeNewMessageDelegate?
    private weak var proxiesManager: ProxiesManaging?
    private weak var proxyKeysManager: ProxyKeysManaging?

    func load(uid: String,
              controller: UIViewController,
              delegate: MakeNewMessageDelegate,
              proxiesManager: ProxiesManaging,
              proxyKeysManager: ProxyKeysManaging) {
        self.uid = uid
        self.controller = controller
        self.delegate = delegate
        self.proxiesManager = proxiesManager
        self.proxyKeysManager = proxyKeysManager
        makeButtons()
        controller.navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
    }
}

private extension ConvosButtonManager {
    func makeButtons() {
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
    }

    @objc func makeNewProxy() {
        guard
            let uid = uid,
            let proxyCount = proxiesManager?.proxies.count else {
                return
        }
        animate(makeNewProxyButton)
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
            let proxiesManager = proxiesManager,
            let proxyKeysManager = proxyKeysManager else {
                return
        }
        animate(makeNewMessageButton)
        makeNewMessageButton.isEnabled = false
        delegate?.showMakeNewMessageController(sender: nil, uid: uid, proxiesManager: proxiesManager, proxyKeysManager: proxyKeysManager, controller: controller)
        makeNewMessageButton.isEnabled = true
    }
}
