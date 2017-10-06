import UIKit

class ConvosManager: ConvosManaging {
    let observer = ConvosObserver()
    weak var tableView: UITableView?
    var convos = [Convo]() { didSet { tableView?.reloadData() } }

    func load(convosOwner owner: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convosOwner: owner, manager: self)
    }
}
