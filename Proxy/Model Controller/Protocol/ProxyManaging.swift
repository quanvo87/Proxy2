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

    func load(ownerId: String, proxyKey: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(ownerId: ownerId, proxyKey: proxyKey, manager: self)
    }
}
