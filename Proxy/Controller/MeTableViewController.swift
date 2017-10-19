import UIKit

class MeTableViewController: UITableViewController {
//    private let authManager = MeAuthManager()
    private let dataSource = MeTableViewDataSource()
    private let delegate = MeTableViewDelegate()
    private let messagesReceivedManager = MessagesReceivedManager()
    private let messagesSentManager = MessagesSentManager()
    private let proxiesInteractedWithManager = ProxiesInteractedWithManager()

    override func viewDidLoad() {
        super.viewDidLoad()
//        authManager.load(self)
        dataSource.load(messagesReceivedManager: messagesReceivedManager,
                        messagesSentManager: messagesSentManager,
                        proxiesInteractedWithManager: proxiesInteractedWithManager,
                        tableView: tableView)
        delegate.load(self)
    }

    func logIn() {
        messagesReceivedManager.load(uid: Shared.shared.uid, tableView: tableView)
        messagesSentManager.load(uid: Shared.shared.uid, tableView: tableView)
        proxiesInteractedWithManager.load(uid: Shared.shared.uid, tableView: tableView)
    }
}
