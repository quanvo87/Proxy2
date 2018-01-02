import UIKit

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

    func observe() {
        observer.observe()
    }

    func stopObserving() {
        observer.stopObserving()
    }
}
