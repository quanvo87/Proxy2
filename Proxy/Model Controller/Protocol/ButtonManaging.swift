import UIKit

typealias ButtonManaging = ButtonEditing & ButtonMaking & ButtonOwning

protocol ButtonEditing: ButtonOwning {
    var itemsToDeleteManager: ItemsToDeleteManaging? { get }
    var navigationItem: UINavigationItem? { get }
    var tableView: UITableView? { get }
}

extension ButtonEditing {
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

    func setDefaultButtons() {
        itemsToDeleteManager?.itemsToDelete.removeAll()
        navigationItem?.leftBarButtonItem = deleteButton
        navigationItem?.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        tableView?.setEditing(false, animated: true)
    }

    func setEditModeButtons() {
        navigationItem?.leftBarButtonItem = cancelButton
        navigationItem?.rightBarButtonItems = [confirmButton]
        tableView?.setEditing(true, animated: true)
    }
}

@objc protocol ButtonMaking: ButtonOwning {
    func _deleteSelectedItems()
    func _makeNewProxy()
    func _setDefaultButtons()
    func _setEditModeButtons()
    func _showMakeNewMessageController()
}

extension ButtonMaking {
    func makeButtons() {
        cancelButton = UIBarButtonItem.make(target: self, action: #selector(_setDefaultButtons), imageName: ButtonName.cancel)
        confirmButton = UIBarButtonItem.make(target: self, action: #selector(_deleteSelectedItems), imageName: ButtonName.confirm)
        deleteButton = UIBarButtonItem.make(target: self, action: #selector(_setEditModeButtons), imageName: ButtonName.delete)
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(_showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(_makeNewProxy), imageName: ButtonName.makeNewProxy)
    }
}

@objc protocol ButtonOwning {
    var cancelButton: UIBarButtonItem { get set }
    var confirmButton: UIBarButtonItem { get set }
    var deleteButton: UIBarButtonItem { get set }
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
}
