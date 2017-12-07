import UIKit

class MessagesReceivedCountManager: MessagesReceivedCountManaging {
    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let messagesReceivedObserver = MessagesReceivedObserver()
    private weak var tableView: UITableView?
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        messagesReceivedObserver.observe(uid: uid, manager: self)
    }
}
