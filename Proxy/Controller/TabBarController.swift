import FirebaseAuth
import UIKit

class TabBarController: UITabBarController {
    let user: User

    init(_ user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let messagesController = MessagesTableViewController2(user.uid)
        messagesController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)
        viewControllers = [messagesController].map {
            UINavigationController(rootViewController: $0)
        }
    }
}
