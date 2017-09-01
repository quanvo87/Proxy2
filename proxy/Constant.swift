enum ButtonName: String {
    case cancel
    case confirm
    case delete
    case makeNewMessage
    case makeNewProxy
}

struct Child {
    static let app = "app"

    // Objects
    static let Proxies = "proxies"
    static let ProxyOwners = "proxyOwners"
    static let Convos = "convos"
    static let Messages = "messages"
    static let WordBank = "wordBank"
    static let Icons = "icons"
    static let UserFiles = "userFiles"

    // Proxy
    static let ProxyKeys = "proxyKeys"

    // User
    static let UserInfo = "userInfo"
    static let ProxiesInteractedWith = "proxiesInteractedWith"
    static let MessagesSent = "messagesSent"
    static let MessagesReceived = "messagesReceived"
    static let Blocked = "blocked"
    static let Present = "present"
    static let Typing = "typing"
    
    // Convo
    static let ReceiverDeletedProxy = "receiverDeletedProxy"
    static let ReceiverIsBlocked = "receiverIsBlocked"
    static let ReceiverLeftConvo = "receiverLeftConvo"
    static let ReceiverNickname = "receiverNickname"
    static let SenderDeletedProxy = "senderDeletedProxy"
    static let SenderIsBlocked = "senderIsBlocked"
    static let SenderNickname = "senderNickname"
    static let SenderLeftConvo = "senderLeftConvo"

    // Message
    static let Read = "read"
    static let TimeRead = "timeRead"
    static let MediaType = "mediaType"
    static let MediaURL = "mediaURL"
    
    // Shared
    static let Key = "key"
    static let Name = "name"
    static let Nickname = "nickname"
    static let Icon = "icon"
    static let Message = "message"
    static let Created = "created"
    static let Timestamp = "timestamp"
    static let unreadCount = "unreadCount"
}

struct URLs {
    static let Storage = "gs://proxy-98b45.appspot.com"
}

struct Settings {
    static let MaxAllowedProxies = UInt(30)
    static let TimeBetweenTimestamps = 30.0
    static let newProxyDuration: Double = 60 * 5
}

struct Identifier {
    static let TabBarController = "Tab Bar Controller"
    static let LoginViewController = "Login View Controller"
    
    static let ProxyInfoTableViewController = "Proxy Info Table View Controller"
    static let ProxyCell = "Proxy Cell"
    static let SenderProxyInfoCell = "Sender Proxy Info Cell"
    static let ReceiverProxyInfoCell = "Receiver Proxy Info Cell"
    
    static let IconPickerCollectionViewController = "Icon Picker Collection View Controller"
    static let IconPickerCell = "Icon Picker Cell"
    
    static let NewMessageViewController = "New Message View Controller"
    static let SenderPickerTableViewController = "Sender Picker Table View Controller"
    static let ReceiverPickerViewController = "Receiver Picker View Controller"
    
    static let ConvoViewController = "Convo View Controller"
    static let ConvoInfoTableViewController = "Convo Info Table View Controller"
    static let ConvoCell = "Convo Cell"
    
    static let MeTableViewCell = "Me Table View Cell"
    static let BlockedUsersTableViewController = "Blocked Users Table View Controller"
    static let BlockedUsersTableViewCell = "Blocked Users Table View Cell"
    
    static let Cell = "Cell"
}

struct UISetting {
    static let navBarButtonCGDouble = 30.0
    static let navBarButtonCGRect = CGRect(x: 0, y: 0, width: UISetting.navBarButtonCGDouble, height: UISetting.navBarButtonCGDouble)
    static let navBarButtonCGSize = CGSize(width: UISetting.navBarButtonCGDouble, height: UISetting.navBarButtonCGDouble)
}
