import UIKit

class MessagesAuthManager: AuthManaging {
    let observer = AuthObserver()
    weak var controller: MessagesTableViewController?
    weak var storyboard: UIStoryboard?

    func load(_ controller: MessagesTableViewController) {
        self.controller = controller
        observer.observe(self)
    }

    func logIn() {
        guard let controller = controller else { return }
        controller.buttonManager.load(controller)
        controller.convosManager.load(convosOwner: Shared.shared.uid, reloader: controller.reloader)
        controller.dataSource.manager = controller.convosManager
        controller.delegate.controller = controller
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
        tab0.image = UIImage(named: "messages")
        tab1.image = UIImage(named: "proxies")
        tab2.image = UIImage(named: "me")
    }
}
