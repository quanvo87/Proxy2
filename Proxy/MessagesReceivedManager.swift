import UIKit

class MessagesReceivedManager: MessagesReceivedManaging {
    private let observer = MessagesReceivedObserver()
    private weak var tableView: UITableView?

    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
