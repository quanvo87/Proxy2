import UIKit

class ProxiesInteractedWithCountManager: ProxiesInteractedWithCountManaging {
    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let observer = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
