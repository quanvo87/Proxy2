import UIKit

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
    func load(uid: String, tableView: UITableView, controller: UIViewController?)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            controller?.title = "My Proxies\(proxies.count.asStringWithParens)"
            controller?.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"
            tableView?.reloadData()
        }
    }

    private let observer = ProxiesObserver()
    private weak var tableView: UITableView?
    private weak var controller: UIViewController?

    func load(uid: String, tableView: UITableView, controller: UIViewController?) {
        self.tableView = tableView
        self.controller = controller
        observer.observe(uid: uid, manager: self)
    }
}
