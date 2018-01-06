import UIKit

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
    func load(uid: String, controller: UIViewController?, manager: ButtonManaging?, tableView: UITableView)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            if let manager = manager {
                if proxies.isEmpty {
                    manager.animate(manager.makeNewProxyButton, loop: true)
                } else {
                    manager.stopAnimating(manager.makeNewProxyButton)
                }
            }

            controller?.title = "My Proxies\(proxies.count.asStringWithParens)"
            controller?.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"

            tableView?.reloadData()
        }
    }

    private let observer = ProxiesObserver()
    private weak var controller: UIViewController?
    private weak var manager: ButtonManaging?
    private weak var tableView: UITableView?

    func load(uid: String, controller: UIViewController?, manager: ButtonManaging?, tableView: UITableView) {
        self.controller = controller
        self.manager = manager
        self.tableView = tableView
        observer.observe(uid: uid, manager: self)
    }
}
