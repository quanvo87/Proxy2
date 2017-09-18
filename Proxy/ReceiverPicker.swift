import UIKit

class ReceiverPicker {
    private weak var okAction: UIAlertAction?
    private weak var viewController: MakeNewMessageViewController?

    init(_ viewController: MakeNewMessageViewController) {
        self.viewController = viewController
    }

    func start() {
        let alert = UIAlertController(title: "Enter Receiver Name", message: "Proxy names only. Nicknames do not work.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert = alert] _ in
            guard let text = alert?.textFields?[safe: 0]?.text?.lowercased() else { return }
            self.setReceiver(text)
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField { (textField) in
            textField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        }
        self.okAction = okAction
        viewController?.present(alert, animated: true)
        okAction.isEnabled = false
    }
}

private extension ReceiverPicker {
    func setReceiver(_ key: String) {
        DBProxy.getProxy(withKey: key, completion: { (proxy) in
            guard let proxy = proxy else {
                self.showErrorAlert(title: "Receiver Not Found", message: "Please try again.")
                return
            }
            guard proxy.ownerId != Shared.shared.uid else {
                self.showErrorAlert(title: "Cannot Send Message To Your Own Proxy", message: "Please try again.")
                return
            }
            self.viewController?.receiver = proxy
        })
    }

    func showErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.start()
        })
        viewController?.present(alert, animated: true)
    }

    @objc func textFieldDidChange(_ sender: UITextField) {
        okAction?.isEnabled = !(sender.text?.isEmpty ?? true)
    }
}
