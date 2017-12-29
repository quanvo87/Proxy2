import UIKit

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            navigationItem?.title = "My Proxies\(proxies.count.asStringWithParens)"
            tableView?.reloadData()
        }
    }

    let observer = ProxiesObserver()
    weak var navigationItem: UINavigationItem?
    private weak var tableView: UITableView?

    func load(uid: String, navigationItem: UINavigationItem?, tableView: UITableView?) {
        self.navigationItem = navigationItem
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
