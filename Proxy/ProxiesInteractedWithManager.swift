import UIKit

class ProxiesInteractedWithManager: ProxiesInteractedWithManaging {
    private let observer = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }

    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }
}
