import FirebaseDatabase
import UIKit

protocol ProxiesManaging: ReferenceObserving {
    var proxies: [Proxy] { get set }
    func addController(_ controller: UIViewController)
    func addManager(_ manager: ButtonManaging)
    func addTableView(_ tableView: UITableView)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            for controller in controllers.allObjects {
                guard let controller = controller as? UIViewController else {
                    continue
                }
                controller.title = "My Proxies\(proxies.count.asStringWithParens)"
                controller.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"
            }
            for manager in managers.allObjects {
                guard let manager = manager as? ButtonManaging else {
                    continue
                }
                if proxies.isEmpty {
                    manager.animateButton()
                } else {
                    manager.stopAnimatingButton()
                }
            }
            for tableView in tableViews.allObjects {
                guard let tableView = tableView as? UITableView else {
                    continue
                }
                tableView.reloadData()
            }
        }
    }
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private let controllers = NSHashTable<AnyObject>(options: .weakMemory)
    private let managers = NSHashTable<AnyObject>(options: .weakMemory)
    private let tableViews = NSHashTable<AnyObject>(options: .weakMemory)

    init(_ uid: String) {
        ref = DB.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak self] (data) in
            self?.proxies = data.toProxiesArray(uid: uid).reversed()
        }
    }

    func addController(_ controller: UIViewController) {
        controllers.add(controller)
    }

    func addManager(_ manager: ButtonManaging) {
        managers.add(manager)
    }

    func addTableView(_ tableView: UITableView) {
        tableViews.add(tableView)
    }

    deinit {
        stopObserving()
    }
}
