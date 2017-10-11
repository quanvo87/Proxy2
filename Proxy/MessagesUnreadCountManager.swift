import UIKit

class MessagesUnreadCountManager: UnreadCountManaging {
    let observer = UnreadCountObserver()
    weak var controller: UIViewController?
    
    func load(_ controller: UIViewController) {
        self.controller = controller
        observer.observe(manager: self, uid: Shared.shared.uid)
    }
    
    func setUnreadCount(_ count: Int?) {
        if let count = count {
            controller?.navigationItem.title = "Messages" + count.asLabelWithParens
            controller?.tabBarController?.tabBar.items?.first?.badgeValue = count == 0 ? nil : String(count)
        } else {
            controller?.navigationItem.title = "Messages"
            controller?.tabBarController?.tabBar.items?.first?.badgeValue = nil
        }
    }
}
