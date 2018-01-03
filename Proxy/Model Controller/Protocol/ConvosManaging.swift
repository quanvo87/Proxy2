import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt)
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private let observer = ConvosObserver()
    private weak var tableView: UITableView?

    func load(uid: String, proxyKey: String?, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(uid: uid, proxyKey: proxyKey, manager: self)
    }

    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        observer.loadConvos(endingAtTimestamp: timestamp, querySize: querySize)
    }
}
