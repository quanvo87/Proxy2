struct Child {
    static let blockedUsers = "blockedUsers"
    static let convos = "convos"
    static let isPresent = "isPresent"
    static let isTyping = "isTyping"
    static let key = "key"
    static let messages = "messages"
    static let proxies = "proxies"
    static let proxyKeys = "proxyKeys"
    static let proxyOwners = "proxyOwners"
    static let timestamp = "timestamp"
    static let unreadCount = "unreadCount"
    static let unreadMessages = "unreadMessages"
    static let userInfo = "userInfo"
    static let userFiles = "userFiles"
}



struct Identifier {
    static let tabBarController = "TabBarController"
    static let LoginViewController = "LoginViewController"
    
    static let ProxyTableViewController = "ProxyTableViewController"
    static let ProxyCell = "ProxyCell"
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

struct Setting {
    static let maxAllowedProxies = UInt(30)
    static let newProxyBadgeDuration: Double = 60 * 5
    static let timeBetweenTimestamps = 30.0
}

struct UISetting {
    static let navBarButtonCGDouble = 30.0
    static let navBarButtonCGRect = CGRect(x: 0, y: 0, width: UISetting.navBarButtonCGDouble, height: UISetting.navBarButtonCGDouble)
    static let navBarButtonCGSize = CGSize(width: UISetting.navBarButtonCGDouble, height: UISetting.navBarButtonCGDouble)
}
