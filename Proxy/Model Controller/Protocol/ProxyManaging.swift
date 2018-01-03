import UIKit

protocol ProxyManaging: class {
    var proxy: Proxy? { get set }
}

class ProxyManager: ProxyManaging {
    var proxy: Proxy? {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = ProxyObserver()
    private weak var tableView: UITableView?

    func load(uid: String, key: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, key: key, manager: self)
    }
}
