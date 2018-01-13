import FirebaseDatabase
import UIKit

protocol ProxiesManaging: ReferenceObserving {
    var proxies: [Proxy] { get set }
    func addAnimator(_ animator: ButtonAnimating)
    func addController(_ controller: UIViewController)
    func addTableView(_ tableView: UITableView)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            for animator in animators.allObjects {
                guard let animator = animator as? ButtonAnimating else {
                    continue
                }
                if proxies.isEmpty {
                    animator.animateButton()
                } else {
                    animator.stopAnimatingButton()
                }
            }
            for controller in controllers.allObjects {
                guard let controller = controller as? UIViewController else {
                    continue
                }
                controller.title = "My Proxies\(proxies.count.asStringWithParens)"
                controller.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"
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
    private let animators = NSHashTable<AnyObject>(options: .weakMemory)
    private let controllers = NSHashTable<AnyObject>(options: .weakMemory)
    private let tableViews = NSHashTable<AnyObject>(options: .weakMemory)

    init(_ uid: String) {
        ref = DB.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak self] (data) in
            self?.proxies = data.toProxiesArray(uid: uid).reversed()
        }
    }

    func addAnimator(_ animator: ButtonAnimating) {
        animators.add(animator)
    }

    func addController(_ controller: UIViewController) {
        controllers.add(controller)
    }

    func addTableView(_ tableView: UITableView) {
        tableViews.add(tableView)
    }

    deinit {
        stopObserving()
    }
}
