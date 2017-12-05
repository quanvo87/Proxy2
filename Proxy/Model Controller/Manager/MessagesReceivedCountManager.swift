import UIKit

class MessagesReceivedCountManager: MessagesReceivedCountManaging {
    private let messagesReceivedObserver = MessagesReceivedObserver()
    private weak var tableView: UITableView?

    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        messagesReceivedObserver.observe(messagesReceivedCountManager: self, uid: uid)
    }
}
