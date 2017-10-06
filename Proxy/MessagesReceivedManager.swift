import UIKit

class MessagesReceivedManager: MessagesReceivedManaging {
    let observer = MessagesReceivedObserver()
    weak var tableView: UITableView?
    var messagesReceivedCount = "-" { didSet { tableView?.reloadData() } }

    func load(tableView: UITableView, uid: String) {
        self.tableView = tableView
        observer.observe(manager: self, uid: uid)
    }
}
