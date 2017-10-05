import UIKit

class TableViewReloader: ViewReloading {
    weak var tableView: UITableView?

    func reload() {
        tableView?.reloadData()
    }
}
