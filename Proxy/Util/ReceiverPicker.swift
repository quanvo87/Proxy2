import UIKit

class ReceiverPicker {
    private let uid: String
    weak var okAction: UIAlertAction?
    weak var controller: MakeNewMessageViewController?

    init(controller: MakeNewMessageViewController, uid: String) {
        self.controller = controller
        self.uid = uid
    }

    func load() {
        let alert = UIAlertController(title: "Enter Receiver Name", message: "Proxy names only. Nicknames do not work.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert = alert] _ in
            guard let text = alert?.textFields?[safe: 0]?.text?.lowercased() else {
                return
            }
            self.setReceiver(text)
        }
        self.okAction = okAction
        okAction.isEnabled = false
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField { (textField) in
            textField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        }
        controller?.present(alert, animated: true)
    }
}

private extension ReceiverPicker {
    func setReceiver(_ key: String) {
        DBProxy.getProxy(withKey: key) { (proxy) in
            guard let proxy = proxy else {
                self.showErrorAlert(title: "Receiver Not Found", message: "Please try again.")
                return
            }
            guard proxy.ownerId != self.uid else {
                self.showErrorAlert(title: "Cannot Send Message To Your Own Proxy", message: "Please try again.")
                return
            }
            self.controller?.receiver = proxy
        }
    }

    func showErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.load()
        })
        controller?.present(alert, animated: true)
    }

    @objc func textFieldDidChange(_ sender: UITextField) {
        okAction?.isEnabled = !(sender.text?.isEmpty ?? true)
    }
}
