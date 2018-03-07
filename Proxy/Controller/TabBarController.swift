import UIKit

class TabBarController: UITabBarController {
    private let convosViewController: ConvosViewController
    private let database: Database
    private let uid: String
    private var didHideConvoObserver: NSObjectProtocol?
    private var didShowConvoObserver: NSObjectProtocol?
    private var currentConvoKey: String?

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

        didHideConvoObserver = NotificationCenter.default.addObserver(
            forName: .didHideConvo,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.currentConvoKey = nil
        }

        didShowConvoObserver = NotificationCenter.default.addObserver(
            forName: .didShowConvo,
            object: nil,
            queue: .main) { [weak self] notification in
                if let convoKey = notification.userInfo?["convoKey"] as? String {
                    self?.currentConvoKey = convoKey
                }
        }
    }

    deinit {
        if let didHideConvoObserver = didHideConvoObserver {
            NotificationCenter.default.removeObserver(didHideConvoObserver)
        }
        if let currentConvoKeyObserver = didShowConvoObserver {
            NotificationCenter.default.removeObserver(currentConvoKeyObserver)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TabBarController: ConvoShowing {
    func showConvo(_ convoKey: String) {
        guard convoKey != currentConvoKey else {
            return
        }
        // todo: move convo retrieval to serverless function
        database.getConvo(convoKey: convoKey, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            case .success(let convo):
                self?.selectedIndex = 0
                self?.convosViewController.navigationController?.popToRootViewController(animated: false)
                self?.convosViewController.showConvoViewController(convo)
            }
        }
    }
}
