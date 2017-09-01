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

    static func makeCancelButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        return makeButton(target: target, selector: selector, imageName: "Cancel")
    }

    mutating func makeButtons(_ delegate: ButtonManagerDelegate) {
        cancelButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: "Cancel")
        confirmButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: "Confirm")
        deleteButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: "Delete")
        newMessageButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: "New Message")
        newProxyButton = ButtonManager.makeButton(target: delegate, selector: #selector(delegate.makeNewProxy), imageName: "Create New Proxy")
    }

    private static func makeButton(target: Any?, selector: Selector, imageName: String) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.frame = UISetting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName), for: .normal)
        return UIBarButtonItem(customView: button)
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
