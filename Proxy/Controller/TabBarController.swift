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

        let messagesController = MessagesTableViewController(uid)
        messagesController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesController = ProxiesTableViewController(uid)
        proxiesController.tabBarItem = UITabBarItem(title: "Proxies", image: UIImage(named: "proxies"), tag: 1)

        viewControllers = [messagesController, proxiesController].map {
            UINavigationController(rootViewController: $0)
        }
    }
}
