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
        dataSource.load(self)
        delegate.load(self)
    }
}
