import UIKit

struct ButtonManager {
    private(set) var cancelButton = UIBarButtonItem()
    private(set) var confirmButton = UIBarButtonItem()
    private(set) var deleteButton = UIBarButtonItem()
    private(set) var makeNewMessageButton = UIBarButtonItem()
    private(set) var makeNewProxyButton = UIBarButtonItem()

    private(set) var itemsToDelete = [String: Any]()

    init() {}
}

extension ButtonManager {
    mutating func itemsToDeleteRemoveAll() {
        itemsToDelete.removeAll()
    }

    mutating func itemsToDeleteRemoveValue(forKey key: String) {
        itemsToDelete.removeValue(forKey: key)
    }

    mutating func itemsToDeleteSet(value: Any, forKey key: String) {
        itemsToDelete[key] = value
    }
}

extension ButtonManager {
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

    static func makeButton(target: Any?, action: Selector, imageName: ButtonName) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.frame = UISetting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName.rawValue), for: .normal)
        return UIBarButtonItem(customView: button)
    }
    
    mutating func makeButtons(_ delegate: ButtonManagerDelegate) {
        cancelButton = ButtonManager.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .cancel)
        confirmButton = ButtonManager.makeButton(target: delegate, action: #selector(delegate.deleteSelectedItems), imageName: .confirm)
        deleteButton = ButtonManager.makeButton(target: delegate, action: #selector(delegate.toggleEditMode), imageName: .delete)
        makeNewMessageButton = ButtonManager.makeButton(target: delegate, action: #selector(delegate.goToMakeNewMessageVC), imageName: .makeNewMessage)
        makeNewProxyButton = ButtonManager.makeButton(target: delegate, action: #selector(delegate.makeNewProxy), imageName: .makeNewProxy)
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
