import UIKit

class MessagesSentCountManager: MessagesSentCountManaging {
    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let messagesSentObserver = MessagesSentObserver()
    private weak var tableView: UITableView?


    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        messagesSentObserver.observe(uid: uid, manager: self)
    }
}
