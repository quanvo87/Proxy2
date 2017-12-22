import UIKit

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = ProxiesObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    func stopObserving() {
        observer.stopObserving()
    }
}
