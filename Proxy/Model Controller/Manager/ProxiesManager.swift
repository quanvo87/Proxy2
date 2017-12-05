import UIKit

class ProxiesManager: ProxiesManaging {
    private let proxiesObserver = ProxiesObserver()
    private weak var tableView: UITableView?

    var proxies = [Proxy]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        proxiesObserver.observe(proxiesManager: self, uid: uid)
    }

    func stopObserving() {
        proxiesObserver.stopObserving()
    }
}
