import UIKit

typealias ButtonManaging = ButtonEditing & ButtonMaking & ButtonOwning

enum ButtonName: String {
    case cancel
    case confirm
    case delete
    case info
    case makeNewMessage
    case makeNewProxy
}

protocol ButtonEditing {}

extension ButtonEditing where Self: ButtonOwning & ItemsDeleting & UITableViewController {
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
        navigationItem.leftBarButtonItem = deleteButton
        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItems = [confirmButton]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            removeAll()
//            itemsToDelete.removeAll()
        }
    }
}

@objc protocol ButtonMaking: ButtonOwning {
    func _deleteSelectedItems()
    func _goToMakeNewMessageVC()
    func _makeNewProxy()
    func _toggleEditMode()
}

extension ButtonMaking {
    func makeButtons() {
        cancelButton = UIBarButtonItem.makeButton(target: self, action: #selector(_toggleEditMode), imageName: .cancel)
        confirmButton = UIBarButtonItem.makeButton(target: self, action: #selector(_deleteSelectedItems), imageName: .confirm)
        deleteButton = UIBarButtonItem.makeButton(target: self, action: #selector(_toggleEditMode), imageName: .delete)
        makeNewMessageButton = UIBarButtonItem.makeButton(target: self, action: #selector(_goToMakeNewMessageVC), imageName: .makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.makeButton(target: self, action: #selector(_makeNewProxy), imageName: .makeNewProxy)
    }
}

@objc protocol ButtonOwning {
    var cancelButton: UIBarButtonItem { get set }
    var confirmButton: UIBarButtonItem { get set }
    var deleteButton: UIBarButtonItem { get set }
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
}

protocol ItemsDeleting: class {
//    var itemsToDelete: [String: Any] { get set }
    func set(_ object: Any, forKey key: String)
    func remove(atKey key: String)
    func removeAll()
}
