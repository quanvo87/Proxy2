import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
}

class ConvosManager: ConvosManaging {
    var convos = [Convo]() {
        didSet {
            convos = convos.cleaned(container)
            tableView?.reloadData()
        }
    }
    
    let observer = ConvosObserver()
    private var container: DependencyContaining = DependencyContainer.container
    private weak var tableView: UITableView?

    func load(convosOwner: String, tableView: UITableView, container: DependencyContaining) {
        self.tableView = tableView
        self.container = container
        observer.observe(convosOwner: convosOwner, manager: self)
    }
}

private extension Collection where Element == Convo {
    func cleaned(_ container: DependencyContaining) -> [Convo] {
        var cleaned = [Convo]()
        for convo in self {
            if container.proxiesManager.proxies.contains(where: { $0.key == convo.senderProxyKey} ) {
                cleaned.append(convo)
            } else {
                DB.delete(convo) { _ in }
            }
        }
        return cleaned
    }
}
