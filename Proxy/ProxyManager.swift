import UIKit

class ProxyManager: ProxyManaging {
    let observer = ProxyObserver()
    weak var tableView: UITableView?
    var proxy: Proxy? { didSet { tableView?.reloadData() } }

    func load(proxy: Proxy, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(manager: self, proxy: proxy)
    }
}
