import UIKit

class ProxiesManager: ProxiesManaging {
    private let observer = ProxiesObserver()
    private weak var tableView: UITableView?

    var proxies = [Proxy]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    func stopObserving() {
        observer.stopObserving()
    }
}
