import UIKit

class MessagesSentCountManager: MessagesSentCountManaging {
    private let messagesSentObserver = MessagesSentObserver()
    private weak var tableView: UITableView?

    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        messagesSentObserver.observe(messagesSentCountManager: self, uid: uid)
    }
}
