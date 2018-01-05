import UIKit

class ConvosButtonManager: ButtonManaging {
    let viewGlower = ViewGlower()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private var container: DependencyContaining = DependencyContainer.container
    private var uid = ""
    private weak var controller: UIViewController?
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?

    func load(container: DependencyContaining,
              uid: String,
              controller: UIViewController,
              makeNewMessageDelegate: MakeNewMessageDelegate) {
        self.container = container
        self.uid = uid
        self.controller = controller
        self.makeNewMessageDelegate = makeNewMessageDelegate
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
        makeNewProxyButton.isEnabled = false
        animateButton(makeNewProxyButton)
        DB.makeProxy(uid: uid, currentProxyCount: container.proxiesManager.proxies.count) { (result) in
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
        animateButton(makeNewMessageButton)
        guard let controller = controller else {
            return
        }
        makeNewMessageDelegate?.showMakeNewMessageController(uid: uid, sender: nil, controller: controller, container: container)
    }
}
