import UIKit

class MessagesReceivedManager: MessagesReceivedManaging {
    private let observer = MessagesReceivedObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
}
