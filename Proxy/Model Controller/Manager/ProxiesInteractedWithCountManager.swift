import UIKit

class ProxiesInteractedWithCountManager: ProxiesInteractedWithCountManaging {
    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let proxiesInteractedWithObserver = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        proxiesInteractedWithObserver.observe(uid: uid, manager: self)
    }
}
