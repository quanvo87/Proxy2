import UIKit

class TabBarController: UITabBarController {
    init(uid: String, displayName: String?) {
        super.init(nibName: nil, bundle: nil)

        let convosController = ConvosViewController(uid: uid)
        convosController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesController = ProxiesViewController(uid: uid)
        proxiesController.tabBarItem = UITabBarItem(title: "Proxies", image: UIImage(named: "proxies"), tag: 1)

        let settingsController = SettingsViewController(uid: uid, displayName: displayName)
        settingsController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings"), tag: 2)

        viewControllers = [convosController, proxiesController, settingsController].map {
            UINavigationController(rootViewController: $0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
