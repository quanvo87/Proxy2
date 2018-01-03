import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt)
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private let observer = ConvosObserver()
    private weak var tableView: UITableView?

    func load(convosOwner: String, proxyKey: String?, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convosOwner: convosOwner, proxyKey: proxyKey, manager: self)
    }

    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        observer.getConvos(endingAtTimestamp: timestamp, querySize: querySize)
    }
}
