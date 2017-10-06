import UIKit

class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    weak var tableView: UITableView?
    var proxies = [Proxy]() { didSet { tableView?.reloadData() } }

    func load(_ tableView: UITableView) {
        self.tableView = tableView
        observer.observe(self)
    }
}
