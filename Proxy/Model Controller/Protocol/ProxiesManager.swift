import UIKit

protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
    func load(animator: ButtonAnimating, controller: UIViewController?, tableView: UITableView?)
}

class ProxiesManager: ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            for object in objects.allObjects {
                switch object {
                case let animator as ButtonAnimating:
                    if proxies.isEmpty {
                        animator.animateButton()
                    } else {
                        animator.stopAnimatingButton()
                    }
                case let controller as UIViewController:
                    controller.title = "My Proxies\(proxies.count.asStringWithParens)"
                    controller.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"
                case let tableView as UITableView:
                    tableView.reloadData()
                default:
                    break
                }
            }
        }
    }

    private let objects = NSHashTable<AnyObject>(options: .weakMemory)
    private let observer = ProxiesObserver()
    private let uid: String

    init(_ uid: String) {
        self.uid = uid
    }

    func load(animator: ButtonAnimating, controller: UIViewController?, tableView: UITableView?) {
        objects.add(animator)
        objects.add(controller)
        objects.add(tableView)
        observer.observe(uid: uid, manager: self)
    }
}
