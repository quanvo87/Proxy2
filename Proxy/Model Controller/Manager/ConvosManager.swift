import UIKit

class ConvosManager: ConvosManaging {
    private let convosObserver = ConvosObserver()
    private weak var tableView: UITableView?

    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }

    func load(convosOwner: String, tableView: UITableView) {
        self.tableView = tableView
        convosObserver.observe(convosManager: self, convosOwner: convosOwner)
    }
}
