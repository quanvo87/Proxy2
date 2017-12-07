import UIKit

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private let convosObserver = ConvosObserver()
    private weak var tableView: UITableView?

    func load(convosOwner: String, tableView: UITableView) {
        self.tableView = tableView
        convosObserver.observe(convosOwner: convosOwner, manager: self)
    }
}
