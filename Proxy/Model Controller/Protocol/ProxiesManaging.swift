import UIKit

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
    func load(uid: String, navigationItem: UINavigationItem?, tableView: UITableView)
    func observe()
    func stopObserving()
}
