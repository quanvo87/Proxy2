import UIKit
import ViewGlower

class ConvosButtonManager: ButtonManaging {
    let viewGlower = ViewGlower()
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
            let proxyCount = manager?.proxies.count else {
                return
        }
        makeNewProxyButton.isEnabled = false
        animate(makeNewProxyButton)
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { (result) in
            switch result {
            case .failure(let error):
                self.controller?.showAlert(title: "Error Creating Proxy", message: error.description)
            case .success:
                guard
                    let proxiesNavigationController = self.controller?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
            }
            self.controller?.tabBarController?.selectedIndex = 1
            self.makeNewProxyButton.isEnabled = true
        }
    }

    @objc func showMakeNewMessageController() {
        defer {
            makeNewMessageButton.isEnabled = true
        }
        makeNewMessageButton.isEnabled = false
        animate(makeNewMessageButton)
        guard
            let uid = uid,
            let controller = controller,
            let manager = manager else {
                return
        }
        delegate?.showMakeNewMessageController(sender: nil, uid: uid, manager: manager, controller: controller)
    }
}
