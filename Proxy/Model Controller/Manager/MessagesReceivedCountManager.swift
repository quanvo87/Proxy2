import UIKit

class MessagesReceivedCountManager: MessagesReceivedCountManaging {
    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = MessagesReceivedObserver()
    private weak var tableView: UITableView?
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
