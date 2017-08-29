struct NavigationItemManager {
    var newProxyButton = UIBarButtonItem()
    var newMessageButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var cancelButton = UIBarButtonItem()

    var itemsToDelete = [Any]()

    init() {}

    mutating func makeButtons(_ delegate: NavigationItemManagerDelegate) {
        newProxyButton = makeButton(delegate: delegate, selector: #selector(delegate.makeNewProxy), imageName: "new-proxy")
        newMessageButton = makeButton(delegate: delegate, selector: #selector(delegate.goToMakeNewMessageVC), imageName: "new-message")
        deleteButton = makeButton(delegate: delegate, selector: #selector(delegate.toggleEditMode), imageName: "delete")
        confirmButton = makeButton(delegate: delegate, selector: #selector(delegate.deleteSelectedItems), imageName: "confirm")
        cancelButton = makeButton(delegate: delegate, selector: #selector(delegate.toggleEditMode), imageName: "cancel")
    }

    private func makeButton(delegate: NavigationItemManagerDelegate, selector: Selector, imageName: String) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(delegate, action: selector, for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.setImage(UIImage(named: imageName)?.resize(toNewSize: UISettings.navBarButtonCGSize, isAspectRatio: true), for: .normal)
        return UIBarButtonItem(customView: button)
    }
}

@objc protocol NavigationItemManagerDelegate {
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
    func deleteSelectedItems()
    func makeNewProxy()
    func goToMakeNewMessageVC()
}
