import UIKit

class ProxyManager: ProxyManaging {
    private let proxyObserver = ProxyObserver()
    private weak var tableView: UITableView?

    var proxy: Proxy? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(ownerId: String, proxyKey: String, tableView: UITableView) {
        self.tableView = tableView
        proxyObserver.observe(proxyManager: self, ownerId: ownerId, proxyKey: proxyKey)
    }
}
