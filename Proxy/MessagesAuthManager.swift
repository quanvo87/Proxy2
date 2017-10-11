import UIKit

class MessagesAuthManager: AuthManaging {
    let observer = AuthObserver()
    weak var controller: MessagesTableViewController? {
        didSet {
            observer.observe(self)
        }
    }

    func logIn() {
        guard let controller = controller else { return }
        controller.convosManager.load(convosOwner: Shared.shared.uid, tableView: controller.tableView)
        controller.setupButtonManager()
        controller.setupDataSource()
        controller.setupDelegate()
        controller.tabBarController?.tabBar.items?.setupForTabBar()
        controller.unreadCountManager.load(controller)
        Shared.shared.queue.async {
            DBProxy.fixConvoCounts { _ in }
        }
    }
}

private extension Array where Element: UITabBarItem {
    func setupForTabBar() {
        guard
            let tab0 = self[safe: 0],
            let tab1 = self[safe: 1],
            let tab2 = self[safe: 2] else {
                return
        }
        tab0.isEnabled = true
        tab0.image = UIImage(named: "messages")
        tab1.isEnabled = true
        tab1.image = UIImage(named: "proxies")
        tab2.isEnabled = true
        tab2.image = UIImage(named: "me")
    }
}
