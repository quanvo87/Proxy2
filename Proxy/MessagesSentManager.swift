import UIKit

class MessagesSentManager: MessagesSentManaging {
    private let observer = MessagesSentObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
}
