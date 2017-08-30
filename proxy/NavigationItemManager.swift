struct NavigationItemManager {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var newMessageButton = UIBarButtonItem()
    var newProxyButton = UIBarButtonItem()

    var itemsToDelete = [Any]()

    init() {}

    mutating func makeButtons(_ delegate: NavigationItemManagerDelegate) {
        cancelButton = makeButton(delegate: delegate, selector: #selector(delegate.toggleEditMode), imageName: "cancel")
        confirmButton = makeButton(delegate: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: "confirm")
        deleteButton = makeButton(delegate: delegate, selector: #selector(delegate.toggleEditMode), imageName: "delete")
        newMessageButton = makeButton(delegate: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: "new-message")
        newProxyButton = makeButton(delegate: delegate, selector: #selector(delegate.makeNewProxy), imageName: "new-proxy")
    }

    private func makeButton(delegate: NavigationItemManagerDelegate, selector: Selector, imageName: String) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(delegate, action: selector, for: .touchUpInside)
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
