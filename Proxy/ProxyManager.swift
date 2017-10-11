import UIKit

class ProxyManager: ProxyManaging {
    private let observer = ProxyObserver()
    private weak var tableView: UITableView?

    func load(ownerId: String, key: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(ownerId: ownerId, key: key, manager: self)
    }

    var proxy: Proxy? {
        didSet {
            tableView?.reloadData()
        }
    }
}
