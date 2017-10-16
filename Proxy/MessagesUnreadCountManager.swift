import UIKit

class MessagesUnreadCountManager: UnreadCountManaging {
    private let observer = UnreadCountObserver()
    private weak var controller: UIViewController?

    var unreadCount: Int? {
        didSet {
            if let unreadCount = unreadCount {
                controller?.navigationItem.title = "Messages" + unreadCount.asLabelWithParens
                controller?.tabBarController?.tabBar.items?.first?.badgeValue = unreadCount == 0 ? nil : String(unreadCount)
            } else {
                controller?.navigationItem.title = "Messages"
                controller?.tabBarController?.tabBar.items?.first?.badgeValue = nil
            }
        }
    }
    
    func load(_ controller: UIViewController) {
        self.controller = controller
        observer.observe(uid: Shared.shared.uid, manager: self)
    }
}
