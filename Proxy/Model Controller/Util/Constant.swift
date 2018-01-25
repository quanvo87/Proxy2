import UIKit

struct ButtonName {
    static let cancel = "cancel"
    static let confirm = "confirm"
    static let delete = "delete"
    static let info = "info"
    static let makeNewMessage = "makeNewMessage"
    static let makeNewProxy = "makeNewProxy"
}

struct Identifier {
    static let convoDetailReceiverProxyTableViewCell = "ConvoDetailReceiverProxyTableViewCell"
    static let convoDetailSenderProxyTableViewCell = "ConvoDetailSenderProxyTableViewCell"
    static let convosTableViewCell = "ConvosTableViewCell"
    static let iconPickerCollectionViewCell = "IconPickerCollectionViewCell"
    static let makeNewMessageSenderTableViewCell = "MakeNewMessageSenderTableViewCell"
    static let makeNewMessageReceiverTableViewCell = "MakeNewMessageReceiverTableViewCell"
    static let loginViewController = "LoginViewController"
    static let proxiesTableViewCell = "ProxiesTableViewCell"
    static let senderProxyTableViewCell = "SenderProxyTableViewCell"
    static let settingsTableViewCell = "SettingsTableViewCell"
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
    static let receiverNickname = "receiverNickname"
    static let receiverProxyKey = "receiverProxyKey"
    static let senderNickname = "senderNickname"
    static let senderProxyKey = "senderProxyKey"
    static let timestamp = "timestamp"
    static let unreadMessages = "unreadMessages"
    static let userInfo = "userInfo"
}

struct Setting {
    static let maxMessageSize = 20000
    static let maxNameSize = 50
    static let makeProxyRetries = 50
    static let maxProxyCount = 30
    static let navBarButtonCGDouble = 30.0
    static let navBarButtonCGRect = CGRect(x: 0, y: 0, width: Setting.navBarButtonCGDouble, height: Setting.navBarButtonCGDouble)
    static let querySize: UInt = 30
}
