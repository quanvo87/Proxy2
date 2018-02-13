import UIKit

// todo: String(describing: Type.self)
struct Identifier {
    static let convoDetailReceiverProxyTableViewCell = "ConvoDetailReceiverProxyTableViewCell"
    static let convoDetailSenderProxyTableViewCell = "ConvoDetailSenderProxyTableViewCell"
    static let convosTableViewCell = "ConvosTableViewCell"
    static let iconPickerCollectionViewCell = "IconPickerCollectionViewCell"
    static let loginViewController = "LoginViewController"
    static let mainLoginViewController = "MainLoginViewController"
    static let makeNewMessageSenderTableViewCell = "MakeNewMessageSenderTableViewCell"
    static let makeNewMessageReceiverTableViewCell = "MakeNewMessageReceiverTableViewCell"
    static let proxiesTableViewCell = "ProxiesTableViewCell"
    static let senderProxyTableViewCell = "SenderProxyTableViewCell"
    static let settingsTableViewCell = "SettingsTableViewCell"
    static let signUpViewController = "SignUpViewController"
}

struct Child {
    static let convos = "convos"
    static let hasUnreadMessage = "hasUnreadMessage"
    static let icon = "icon"
    static let key = "key"
    static let lastMessage = "lastMessage"
    static let messages = "messages"
    static let name = "name"
    static let parentConvoKey = "parentConvoKey"
    static let proxies = "proxies"
    static let proxyNames = "proxyNames"
    static let receiverDeletedProxy = "receiverDeletedProxy"
    static let receiverProxyKey = "receiverProxyKey"
    static let timestamp = "timestamp"
    static let unreadMessages = "unreadMessages"
    static let userInfo = "userInfo"
}

struct Setting {
    static let navBarButtonCGDouble = 30.0
    static let navBarButtonCGRect = CGRect(x: 0, y: 0, width: Setting.navBarButtonCGDouble, height: Setting.navBarButtonCGDouble)
    static let querySize: UInt = 30
}
