import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt)
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
//            convos = convos.cleaned(container)
            tableView?.reloadData()
        }
    }
    
    private let observer = ConvosObserver()
    private var container: DependencyContaining = DependencyContainer.container
    private weak var tableView: UITableView?

    func load(convosOwner: String, proxyKey: String?, tableView: UITableView, container: DependencyContaining) {
        self.tableView = tableView
        self.container = container
        observer.observe(convosOwner: convosOwner, proxyKey: proxyKey, manager: self)
    }

    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        observer.getConvos(endingAtTimestamp: timestamp, querySize: querySize)
    }
}

private extension Collection where Element == Convo {
    func cleaned(_ container: DependencyContaining) -> [Convo] {
        var cleaned = [Convo]()
        for convo in self {
            if container.proxiesManager.proxies.contains(where: { $0.key == convo.senderProxyKey} ) {
                cleaned.append(convo)
            } else {
                DB.delete(convo, asSender: true) { _ in }
            }
        }
        return cleaned
    }
}
