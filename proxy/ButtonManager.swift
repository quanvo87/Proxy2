struct ButtonManager {
    private var _cancelButton = UIBarButtonItem()
    private var _confirmButton = UIBarButtonItem()
    private var _deleteButton = UIBarButtonItem()
    private var _makeNewMessageButton = UIBarButtonItem()
    private var _makeNewProxyButton = UIBarButtonItem()

    private var _itemsToDelete = [String: Any]()

    init() {}
}

extension ButtonManager {
    var cancelButton: UIBarButtonItem {
        return _cancelButton
    }

    var confirmButton: UIBarButtonItem {
        return _confirmButton
    }

    var deleteButton: UIBarButtonItem {
        return _deleteButton
    }

    var makeNewMessageButton: UIBarButtonItem {
        return _makeNewMessageButton
    }

    var makeNewProxyButton: UIBarButtonItem {
        return _makeNewProxyButton
    }
}

extension ButtonManager {
    var itemsToDelete: [String: Any] {
        return _itemsToDelete
    }

    var itemsToDeleteIsEmpty: Bool {
        return _itemsToDelete.isEmpty
    }

    mutating func itemsToDeleteRemoveAll() {
        _itemsToDelete.removeAll()
    }

    mutating func itemsToDeleteRemoveValue(forKey key: String) {
        _itemsToDelete.removeValue(forKey: key)
    }

    mutating func itemsToDeleteSet(value: Any, forKey key: String) {
        _itemsToDelete[key] = value
    }
}

extension ButtonManager {
    func disableButtons() {
        _cancelButton.isEnabled = false
        _confirmButton.isEnabled = false
        _deleteButton.isEnabled = false
        _makeNewMessageButton.isEnabled = false
        _makeNewProxyButton.isEnabled = false
    }

    func enableButtons() {
        _cancelButton.isEnabled = true
        _confirmButton.isEnabled = true
        _deleteButton.isEnabled = true
        _makeNewMessageButton.isEnabled = true
        _makeNewProxyButton.isEnabled = true
    }

    static func makeButton(target: Any?, selector: Selector, imageName: ButtonName) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.frame = UISetting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName.rawValue), for: .normal)
        return UIBarButtonItem(customView: button)
    }
    
    mutating func makeButtons(_ delegate: ButtonManagerDelegate) {
        _cancelButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: .cancel)
        _confirmButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: .confirm)
        _deleteButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: .delete)
        _makeNewMessageButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: .makeNewMessage)
        _makeNewProxyButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.makeNewProxy), imageName: .makeNewProxy)
    }
}

@objc protocol ButtonManagerDelegate {
    func deleteSelectedItems()
    func goToMakeNewMessageVC()
    func makeNewProxy()
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
}
