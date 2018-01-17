import UIKit

class ConvosButtonManager {
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private let uid: String
    private weak var controller: UIViewController?
    private weak var newConvoManager: NewConvoManaging?
    private weak var proxiesManager: ProxiesManaging?

    init(uid: String,
         controller: UIViewController?,
         newConvoManager: NewConvoManaging?,
         proxiesManager: ProxiesManaging?) {
        self.uid = uid
        self.controller = controller
        self.newConvoManager = newConvoManager
        self.proxiesManager = proxiesManager
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
        controller?.navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
    }
}

extension ConvosButtonManager: ButtonManaging {
    func animateButton() {
        makeNewMessageButton.morph(loop: true)
    }

    func stopAnimatingButton() {
        makeNewMessageButton.stopAnimating()
    }
}

private extension ConvosButtonManager {
    @objc func makeNewProxy() {
        guard let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        makeNewProxyButton.isEnabled = false
        makeNewProxyButton.morph()
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
        makeNewMessageButton.isEnabled = false
        makeNewMessageButton.morph()
        newConvoManager?.showMakeNewMessageController(sender: nil, uid: uid, manager: proxiesManager, controller: controller)
        makeNewMessageButton.isEnabled = true
    }
}
