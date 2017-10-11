import UIKit

class MessagesSentManager: MessagesSentManaging {
    let observer = MessagesSentObserver()
    weak var tableView: UITableView?
    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    func load(tableView: UITableView, uid: String) {
        self.tableView = tableView
        observer.observe(manager: self, uid: uid)
    }
}
