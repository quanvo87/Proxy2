import UIKit

class TabBarController: UITabBarController {
    init(uid: String, displayName: String?) {
        super.init(nibName: nil, bundle: nil)

        let convosViewController = ConvosViewController(uid: uid)
        convosViewController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesViewController = ProxiesViewController(uid: uid)
        proxiesViewController.tabBarItem = UITabBarItem(title: "My Proxies", image: UIImage(named: "proxies"), tag: 1)

        let settingsViewController = SettingsViewController(uid: uid, displayName: displayName)
        settingsViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings"), tag: 2)

        viewControllers = [convosViewController, proxiesViewController, settingsViewController].map {
            UINavigationController(rootViewController: $0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
