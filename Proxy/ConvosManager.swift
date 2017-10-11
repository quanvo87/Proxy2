import UIKit

class ConvosManager: ConvosManaging {
    private let observer = ConvosObserver()
    private weak var tableView: UITableView?

    func load(convosOwner: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convosOwner: convosOwner, manager: self)
    }

    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }
}
