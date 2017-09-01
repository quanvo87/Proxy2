struct ButtonManager {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var newMessageButton = UIBarButtonItem()
    var newProxyButton = UIBarButtonItem()

    var itemsToDelete = [String: Any]()

    init() {}

    func disableButtons() {
        cancelButton.isEnabled = false
        confirmButton.isEnabled = false
        deleteButton.isEnabled = false
        newMessageButton.isEnabled = false
        newProxyButton.isEnabled = false
    }

    func enableButtons() {
        cancelButton.isEnabled = true
        confirmButton.isEnabled = true
        deleteButton.isEnabled = true
        newMessageButton.isEnabled = true
        newProxyButton.isEnabled = true
    }

    static func makeButton(target: Any?, selector: Selector, imageName: ButtonName) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.frame = UISetting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName.rawValue), for: .normal)
        return UIBarButtonItem(customView: button)
    }
    
    mutating func makeButtons(_ delegate: ButtonManagerDelegate) {
        cancelButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: .cancel)
        confirmButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: .confirm)
        deleteButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: .delete)
        newMessageButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: .makeNewMessage)
        newProxyButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.makeNewProxy), imageName: .makeNewProxy)
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
