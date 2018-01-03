import UIKit

class TabBarController: UITabBarController {
    let container: DependencyContaining

    init(displayName: String?, uid: String, container: DependencyContaining) {
        self.container = container

        super.init(nibName: nil, bundle: nil)

        let convosController = ConvosViewController(uid: uid, container: container)
        convosController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesController = ProxiesViewController(uid: uid, container: container)
        proxiesController.tabBarItem = UITabBarItem(title: "Proxies", image: UIImage(named: "proxies"), tag: 1)

        let meController = MeViewController(uid: uid, displayName: displayName)
        meController.tabBarItem = UITabBarItem(title: "Me", image: UIImage(named: "me"), tag: 2)

        viewControllers = [convosController, proxiesController, meController].map {
            UINavigationController(rootViewController: $0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
