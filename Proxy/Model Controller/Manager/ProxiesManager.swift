import UIKit

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private let proxiesObserver = ProxiesObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        proxiesObserver.observe(uid: uid, manager: self)
    }

    func stopObserving() {
        proxiesObserver.stopObserving()
    }
}
