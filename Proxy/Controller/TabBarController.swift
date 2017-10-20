import UIKit

class TabBarController: UITabBarController {
    let displayName: String
    let uid: String

    init(displayName: String, uid: String) {
        self.displayName = displayName
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let messagesController = MessagesViewController(uid)
        messagesController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesController = ProxiesViewController(uid)
        proxiesController.tabBarItem = UITabBarItem(title: "Proxies", image: UIImage(named: "proxies"), tag: 1)

        let meController = MeViewController(displayName: displayName, uid: uid)
        meController.tabBarItem = UITabBarItem(title: "Me", image: UIImage(named: "me"), tag: 2)

        viewControllers = [messagesController, proxiesController, meController].map {
            UINavigationController(rootViewController: $0)
        }
    }
}
