import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt)
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            if let manager = manager {
                if convos.isEmpty {
                    manager.animate(manager.makeNewMessageButton, loop: true)
                } else {
                    manager.stopAnimating(manager.makeNewMessageButton)
                }
            }
            tableView?.reloadData()
        }
    }
    
    private let observer = ConvosObserver()
    private weak var manager: ButtonManaging?
    private weak var tableView: UITableView?

    func load(uid: String, proxyKey: String?, manager: ButtonManaging?, tableView: UITableView) {
        self.manager = manager
        self.tableView = tableView
        observer.observe(uid: uid, proxyKey: proxyKey, manager: self)
    }

    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        observer.loadConvos(endingAtTimestamp: timestamp, querySize: querySize)
    }
}
