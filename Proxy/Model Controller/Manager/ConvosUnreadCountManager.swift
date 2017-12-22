import UIKit

class ConvosUnreadCountManager: UnreadCountManaging {
    var unreadCount: Int = 0 {
        didSet {
            if unreadCount == 0 {
                viewController?.navigationItem.title = "Messages"
                viewController?.tabBarController?.tabBar.items?.first?.badgeValue = nil
            } else {
                viewController?.navigationItem.title = "Messages" + unreadCount.asLabelWithParens
                viewController?.tabBarController?.tabBar.items?.first?.badgeValue = unreadCount == 0 ? nil : String(unreadCount)
            }
        }
    }

    private let obersver = UnreadCountObserver()
    private weak var viewController: UIViewController?
    
    func load(uid: String, viewController: UIViewController) {
        self.viewController = viewController
        obersver.observe(uid: uid, manager: self)
    }
}
