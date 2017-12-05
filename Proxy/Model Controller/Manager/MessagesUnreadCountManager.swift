import UIKit

class MessagesUnreadCountManager: UnreadCountManaging {
    private let unreadCountObserver = UnreadCountObserver()
    private weak var viewController: UIViewController?

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
    
    func load(uid: String, viewController: UIViewController) {
        self.viewController = viewController
        unreadCountObserver.observe(uid: uid, unreadCountManager: self)
    }
}
