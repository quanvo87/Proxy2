import UIKit

struct Buttons {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
}

protocol ButtonManaging: class {
    var buttons: Buttons { get set }
    var itemsToDelete: [String: Any] { get set }
    func removeAllItemsToDelete()
    func removeItemToDelete(forKey key: String)
    func setItemToDelete(value: Any, forKey key: String)
    func disableButtons()
    func enableButtons()
    func makeButtons(_ delegate: ButtonManagerDelegate)
}

extension ButtonManaging {
    func removeAllItemsToDelete() {
        itemsToDelete.removeAll()
    }

    func removeItemToDelete(forKey key: String) {
        itemsToDelete.removeValue(forKey: key)
    }

    func setItemToDelete(value: Any, forKey key: String) {
        itemsToDelete[key] = value
    }

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

class ButtonManager {
    private(set) var cancelButton = UIBarButtonItem()
    private(set) var confirmButton = UIBarButtonItem()
    private(set) var deleteButton = UIBarButtonItem()
    private(set) var makeNewMessageButton = UIBarButtonItem()
    private(set) var makeNewProxyButton = UIBarButtonItem()

    private(set) var itemsToDelete = [String: Any]()
}

extension ButtonManager {
    func removeAllItemsToDelete() {
        itemsToDelete.removeAll()
    }

    func removeItemToDelete(forKey key: String) {
        itemsToDelete.removeValue(forKey: key)
    }

    func setItemToDelete(value: Any, forKey key: String) {
        itemsToDelete[key] = value
    }

    func disableButtons() {
        cancelButton.isEnabled = false
        confirmButton.isEnabled = false
        deleteButton.isEnabled = false
        makeNewMessageButton.isEnabled = false
        makeNewProxyButton.isEnabled = false
    }

    func enableButtons() {
        cancelButton.isEnabled = true
        confirmButton.isEnabled = true
        deleteButton.isEnabled = true
        makeNewMessageButton.isEnabled = true
        makeNewProxyButton.isEnabled = true
    }
    
    func makeButtons(_ delegate: ButtonManagerDelegate) {
        cancelButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .cancel)
        confirmButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.deleteSelectedItems), imageName: .confirm)
        deleteButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .delete)
        makeNewMessageButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.goToMakeNewMessageVC), imageName: .makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.makeButton(target: delegate, action: #selector(delegate.makeNewProxy), imageName: .makeNewProxy)
    }
}

enum ButtonName: String {
    case cancel
    case confirm
    case delete
    case makeNewMessage
    case makeNewProxy
}

@objc protocol ButtonManagerDelegate {
    func deleteSelectedItems()
    func goToMakeNewMessageVC()
    func makeNewProxy()
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
}
