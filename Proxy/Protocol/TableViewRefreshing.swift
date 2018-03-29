import UIKit

protocol TableViewRefreshing {
    func refresh(_ tableView: UITableView)
}

class TableViewRefresher: TableViewRefreshing {
    private lazy var timer = Timer()

    func refresh(_ tableView: UITableView) {
        timer = Timer.scheduledTimer(
            withTimeInterval: Constant.tableViewRefreshRate,
            repeats: true) { [weak tableView = tableView] _ in
                tableView?.reloadData()
        }
    }
}
