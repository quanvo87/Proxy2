import UIKit

protocol TableViewReloading: class {
    func reloadTableView()
}

class TableViewReloader: TableViewReloading {
    weak var tableView: UITableView?

    func reloadTableView() {
        tableView?.reloadData()
    }
}
