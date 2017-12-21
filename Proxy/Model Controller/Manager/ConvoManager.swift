import UIKit

class ConvoManager: ConvoManaging {
    var convo = Convo() {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = ConvoObserver()
    private weak var tableView: UITableView?

    func load(convoOwnerId: String, convoKey: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convoOwnerId: convoOwnerId, convoKey: convoKey, manager: self)
    }
}
