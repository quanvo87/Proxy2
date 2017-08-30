struct NavigationItemManager {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var newMessageButton = UIBarButtonItem()
    var newProxyButton = UIBarButtonItem()

    var itemsToDelete = [Any]()

    init() {}

    static func makeCancelButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        return makeButton(target: target, selector: selector, imageName: "Assets/App Icons/Cancel")
    }

    mutating func makeButtons(_ delegate: NavigationItemManagerDelegate) {
        cancelButton = NavigationItemManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: "Assets/App Icons/Cancel")
        confirmButton = NavigationItemManager.makeButton(target: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: "Assets/App Icons/Confirm")
        deleteButton = NavigationItemManager.makeButton(target: delegate, selector: #selector(delegate.toggleEditMode), imageName: "Assets/App Icons/Delete")
        newMessageButton = NavigationItemManager.makeButton(target: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: "Assets/App Icons/New Message")
        newProxyButton = NavigationItemManager.makeButton(target: delegate, selector: #selector(delegate.makeNewProxy), imageName: "Assets/App Icons/Create New Proxy")
    }

    private static func makeButton(target: Any?, selector: Selector, imageName: String) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.frame = UISettings.navBarButtonCGRect
        button.setImage(UIImage(named: imageName)?.resize(toNewSize: UISettings.navBarButtonCGSize, isAspectRatio: true), for: .normal)
        return UIBarButtonItem(customView: button)
    }
}

@objc protocol NavigationItemManagerDelegate {
    func deleteSelectedItems()
    func goToMakeNewMessageVC()
    func makeNewProxy()
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
}
