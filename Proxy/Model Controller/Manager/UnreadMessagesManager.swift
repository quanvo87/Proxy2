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
    
    private let unreadMessagesObserver = UnreadMessagesObserver()
    private weak var convosViewController: UIViewController?

    func load(uid: String, convosViewController: UIViewController) {
        self.convosViewController = convosViewController
        unreadMessagesObserver.observe(uid: uid, manager: self)
    }
}
