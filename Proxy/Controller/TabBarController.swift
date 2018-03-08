import UIKit

class TabBarController: UITabBarController {
    private let convosViewController: ConvosViewController
    private let database: Database
    private let uid: String
    private var shouldShowConvoObserver: NSObjectProtocol?

    init(database: Database = Firebase(), uid: String, displayName: String?) {
        self.database = database
        self.uid = uid
        convosViewController = ConvosViewController(uid: uid)

        super.init(nibName: nil, bundle: nil)

        convosViewController.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "messages"), tag: 0)

        let proxiesViewController = ProxiesViewController(uid: uid)
        proxiesViewController.tabBarItem = UITabBarItem(title: "My Proxies", image: UIImage(named: "proxies"), tag: 1)

        let settingsViewController = SettingsViewController(uid: uid, displayName: displayName)
        settingsViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings"), tag: 2)

        viewControllers = [convosViewController, proxiesViewController, settingsViewController].map {
            UINavigationController(rootViewController: $0)
        }

        shouldShowConvoObserver = NotificationCenter.default.addObserver(
            forName: .shouldShowConvo,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let convo = notification.userInfo?["convo"] as? Convo else {
                    return
                }
                self?.selectedIndex = 0
                self?.convosViewController.navigationController?.popToRootViewController(animated: false)
                self?.convosViewController.showConvoViewController(convo)
        }
    }

    deinit {
        if let shouldShowConvoObserver = shouldShowConvoObserver {
            NotificationCenter.default.removeObserver(shouldShowConvoObserver)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
