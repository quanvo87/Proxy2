import UIKit

class MessagesSentCountManager: MessagesSentCountManaging {
    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = MessagesSentObserver()
    private weak var tableView: UITableView?


    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
