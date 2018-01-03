import UIKit

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
    func load(uid: String, navigationItem: UINavigationItem?, tableView: UITableView)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            navigationItem?.title = "My Proxies\(proxies.count.asStringWithParens)"
            tableView?.reloadData()
        }
    }

    private let observer = ProxiesObserver()
    private weak var navigationItem: UINavigationItem?
    private weak var tableView: UITableView?

    func load(uid: String, navigationItem: UINavigationItem?, tableView: UITableView) {
        self.navigationItem = navigationItem
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
