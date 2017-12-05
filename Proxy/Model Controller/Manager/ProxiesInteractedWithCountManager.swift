import UIKit

class ProxiesInteractedWithCountManager: ProxiesInteractedWithCountManaging {
    private let proxiesInteractedWithObserver = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?

    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        proxiesInteractedWithObserver.observe(proxiesInteractedWithManager: self, uid: uid)
    }
}
