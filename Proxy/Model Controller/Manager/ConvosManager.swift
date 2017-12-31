import UIKit

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }
    let observer = ConvosObserver()
    private weak var tableView: UITableView?

    func load(convosOwner: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convosOwner: convosOwner, manager: self)
    }
}
