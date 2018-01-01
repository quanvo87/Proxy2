import UIKit

class UnreadMessagesManager: UnreadMessagesManaging {
    var convosPresentIn = [String : Bool]()

    var unreadMessages = [Message]() {
        didSet {
            let count = unreadMessages.count
            if count == 0 {
                convosViewController?.navigationItem.title = "Messages"
                convosViewController?.tabBarController?.tabBar.items?.first?.badgeValue = nil
            } else {
                convosViewController?.navigationItem.title = "Messages" + count.asStringWithParens
                convosViewController?.tabBarController?.tabBar.items?.first?.badgeValue = count == 0 ? nil : String(count)
            }
        }
    }
    
    private let unreadMessageAddedObserver = UnreadMessageAddedObserver()
    private let unreadMessageRemovedObserver = UnreadMessageRemovedObserver()
    private weak var convosViewController: UIViewController?

    func load(uid: String, proxiesManager: ProxiesManaging, convosViewController: UIViewController) {
        self.convosViewController = convosViewController
        unreadMessageAddedObserver.observe(uid: uid, proxiesManager: proxiesManager, unreadMessagesManager: self)
        unreadMessageRemovedObserver.observe(uid: uid, manager: self)
    }
}
