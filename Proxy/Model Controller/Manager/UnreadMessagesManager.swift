import UIKit

class UnreadMessagesManager: UnreadMessagesManaging {
    var convosPresentIn = [String : Bool]()

    var unreadMessages = [Message]() {
        didSet {
            let count = unreadMessages.count
            if count == 0 {
                convosViewController?.navigationItem.title = "Messages"
                convosViewController?.tabBarController?.tabBar.items?.first?.badgeValue = nil
                proxiesViewController?.navigationItem.title = "My Proxies"
            } else {
                convosViewController?.navigationItem.title = "Messages" + count.asStringWithParens
                convosViewController?.tabBarController?.tabBar.items?.first?.badgeValue = count == 0 ? nil : String(count)
                proxiesViewController?.navigationItem.title = "My Proxies" + count.asStringWithParens
            }
        }
    }
    
    private let unreadMessagesObserver = UnreadMessagesObserver()
    private weak var convosViewController: UIViewController?
    private weak var proxiesViewController: UIViewController?

    func load(uid: String, convosViewController: UIViewController, proxiesViewController: UIViewController) {
        self.convosViewController = convosViewController
        self.proxiesViewController = proxiesViewController
        unreadMessagesObserver.observe(uid: uid, manager: self)
    }
}
