import UIKit

protocol TableViewRefreshing {
    func refresh(_ tableView: UITableView)
}

class TableViewRefresher: TableViewRefreshing {
    private let timeInterval: TimeInterval
    private lazy var timer = Timer()

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    func refresh(_ tableView: UITableView) {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak tableView = tableView] _ in
            tableView?.reloadData()
        }
    }
}
