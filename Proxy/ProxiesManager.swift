import UIKit

class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    var proxies = [Proxy]() {
        didSet {
            tableView?.reloadData()
        }
    }
}
