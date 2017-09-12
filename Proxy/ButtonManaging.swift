import UIKit

protocol ButtonManaging: class {
    var buttons: Buttons { get set }
    func disableButtons()
    func enableButtons()
    func makeButtons(_ delegate: ButtonManagerDelegate)
}

extension ButtonManaging {
    func disableButtons() {
        buttons.cancelButton.isEnabled = false
        buttons.confirmButton.isEnabled = false
        buttons.deleteButton.isEnabled = false
        buttons.makeNewMessageButton.isEnabled = false
        buttons.makeNewProxyButton.isEnabled = false
    }

    func enableButtons() {
        buttons.cancelButton.isEnabled = true
        buttons.confirmButton.isEnabled = true
        buttons.deleteButton.isEnabled = true
        buttons.makeNewMessageButton.isEnabled = true
        buttons.makeNewProxyButton.isEnabled = true
    }

    func makeButtons(_ delegate: ButtonManagerDelegate) {
        buttons.cancelButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .cancel)
        buttons.confirmButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.deleteSelectedItems), imageName: .confirm)
        buttons.deleteButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .delete)
        buttons.makeNewMessageButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.goToMakeNewMessageVC), imageName: .makeNewMessage)
        buttons.makeNewProxyButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.makeNewProxy), imageName: .makeNewProxy)
    }
}

enum ButtonName: String {
    case cancel
    case confirm
    case delete
    case makeNewMessage
    case makeNewProxy
}

struct Buttons {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
}

@objc protocol ButtonManagerDelegate {
    func deleteSelectedItems()
    func goToMakeNewMessageVC()
    func makeNewProxy()
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
}
