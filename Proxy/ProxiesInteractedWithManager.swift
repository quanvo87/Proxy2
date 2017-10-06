import UIKit

class ProxiesInteractedWithManager: ProxiesInteractedWithManaging {
    let observer = ProxiesInteractedWithObserver()
    weak var tableView: UITableView?
    var proxiesInteractedWithCount = "-" { didSet { tableView?.reloadData() } }

    func load(tableView: UITableView, uid: String) {
        self.tableView = tableView
        observer.observe(manager: self, uid: uid)
    }
}
