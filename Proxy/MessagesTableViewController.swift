import UIKit

class MessagesTableViewController: UITableViewController, MakeNewMessageDelegate {
    let authManager = MessagesAuthManager()
    let buttonManager = MessagesButtonManager()
    let convosManager = ConvosManager()
    let dataSource = MessagesTableViewDataSource()
    let delegate = MessagesTableViewDelegate()
    let unreadCountManager = MessagesUnreadCountManager()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Messages"
        setupAuthManager()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = delegate
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        for item in tabBarController?.tabBar.items ?? [] {
            item.isEnabled = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
            self.newConvo = nil
        }
    }
}

extension MessagesTableViewController {
    func setupAuthManager() {
        authManager.controller = self
    }

    func setupButtonManager() {
        buttonManager.controller = self
    }

    func setupDataSource() {
        dataSource.manager = convosManager
        tableView.dataSource = dataSource
    }

    func setupDelegate() {
        delegate.controller = self
        delegate.convosManager = convosManager
        delegate.itemsToDeleteManager = buttonManager.itemsToDeleteManager
    }
}
