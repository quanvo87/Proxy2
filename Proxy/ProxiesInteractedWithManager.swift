import UIKit

class ProxiesInteractedWithManager: ProxiesInteractedWithManaging {
    private let observer = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?

    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
    
    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
