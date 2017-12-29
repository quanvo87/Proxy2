import UIKit

class ConvosManager: ConvosManaging {
    let observer = ConvosObserver()
    var convos = [Convo]()
    weak var tableView: UITableView?

    func load(convosOwner: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convosOwner: convosOwner, manager: self)
    }
}
