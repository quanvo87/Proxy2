import UIKit

class MeTableViewController: UITableViewController {
    let authManager = MeAuthManager()
    let dataSource = MeTableViewDataSource()
    let delegate = MeTableViewDelegate()
    let messagesReceivedManager = MessagesReceivedManager()
    let messagesSentManager = MessagesSentManager()
    let proxiesInteractedWithManager = ProxiesInteractedWithManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        authManager.load(self)
        setupDatasource()
        setupDelegate()
    }
}

private extension MeTableViewController {
    func setupDatasource() {
        dataSource.messagesReceivedManager = messagesReceivedManager
        dataSource.messagesSentManager = messagesSentManager
        dataSource.proxiesInteractedWithManager = proxiesInteractedWithManager
        tableView.dataSource = dataSource
    }

    func setupDelegate() {
        delegate.controller = self
        tableView.delegate = delegate
    }
}
