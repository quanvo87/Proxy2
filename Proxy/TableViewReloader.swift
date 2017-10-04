import UIKit

class TableViewReloader: TableViewReloading {
    weak var tableView: UITableView?

    func reloadTableView() {
        tableView?.reloadData()
    }
}
