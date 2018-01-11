import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt)
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            if convos.isEmpty {
                animator?.animateButton()
            } else {
                animator?.stopAnimatingButton()
            }
            tableView?.reloadData()
        }
    }
    
    private let observer = ConvosObserver()
    private weak var animator: ButtonAnimating?
    private weak var tableView: UITableView?

    func load(uid: String, proxyKey: String?, animator: ButtonAnimating, tableView: UITableView) {
        self.animator = animator
        self.tableView = tableView
        observer.observe(uid: uid, proxyKey: proxyKey, manager: self, querySize: Setting.querySize)
    }

    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        observer.loadConvos(endingAtTimestamp: timestamp, querySize: querySize)
    }
}
