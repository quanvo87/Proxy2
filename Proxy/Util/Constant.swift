import UIKit

struct Child {
    static let blockedUsers = "blockedUsers"
    static let convos = "convos"
    static let icon = "icon"
    static let isPresent = "isPresent"
    static let isTyping = "isTyping"
    static let key = "key"
    static let messages = "messages"
    static let proxies = "proxies"
    static let proxyKeys = "proxyKeys"
    static let proxyOwners = "proxyOwners"
    static let receiverIsBlocked = "receiverIsBlocked"
    static let receiverNickname = "receiverNickname"
    static let senderLeftConvo = "senderLeftConvo"
    static let senderNickname = "senderNickname"
    static let timestamp = "timestamp"
    static let unreadCount = "unreadCount"
    static let unreadMessages = "unreadMessages"
    static let userInfo = "userInfo"
    static let userFiles = "userFiles"
}

struct Name {
    static let blockedUsersTableViewCell = "BlockedUsersTableViewCell"
    static let blockedUsersTableViewController = "BlockedUsersTableViewController"
    static let convoDetailTableViewCell = "ConvoDetailTableViewCell"
    static let convoDetailTableViewController = "ConvoDetailTableViewController"
    static let convosTableViewCell = "ConvosTableViewCell"
    static let convoViewController = "ConvoViewController"
    static let iconPickerCollectionViewCell = "IconPickerCollectionViewCell"
    static let iconPickerCollectionViewController = "IconPickerCollectionViewController"
    static let makeNewMessageViewController = "MakeNewMessageViewController"
    static let meTableViewCell = "MeTableViewCell"
    static let loginViewController = "LoginViewController"
    static let proxiesTableViewCell = "ProxiesTableViewCell"
    static let proxyTableViewController = "ProxyTableViewController"
    static let receiverProxyTableViewCell = "ReceiverProxyTableViewCell"
    static let senderPickerTableViewController = "SenderPickerTableViewController"
    static let senderProxyTableViewCell = "SenderProxyTableViewCell"
    static let tabBarController = "TabBarController"
}

struct Setting {
    static let maxAllowedProxies = UInt(30)
    static let navBarButtonCGDouble = 30.0
    static let navBarButtonCGRect = CGRect(x: 0, y: 0, width: Setting.navBarButtonCGDouble, height: Setting.navBarButtonCGDouble)
    static let navBarButtonCGSize = CGSize(width: Setting.navBarButtonCGDouble, height: Setting.navBarButtonCGDouble)
    static let newProxyBadgeDuration: Double = 60 * 5
    static let timeBetweenTimestamps = 30.0
}
