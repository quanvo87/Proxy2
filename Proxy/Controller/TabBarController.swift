import UIKit

class TabBarController: UITabBarController {
    let presenceManager: PresenceManaging
    let proxiesManager: ProxiesManaging
    let unreadMessagesManager: UnreadMessagesManaging

    init(uid: String,
         displayName: String?,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        let convosController = ConvosViewController(uid: uid, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        convosController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesController = ProxiesViewController(uid: uid, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        proxiesController.tabBarItem = UITabBarItem(title: "Proxies", image: UIImage(named: "proxies"), tag: 1)

        let settingsController = SettingsViewController(uid: uid, displayName: displayName)
        settingsController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings"), tag: 2)

        viewControllers = [convosController, proxiesController, settingsController].map {
            UINavigationController(rootViewController: $0)
        }

        unreadMessagesManager.setController(convosController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
