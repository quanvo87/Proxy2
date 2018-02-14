import Firebase
import FirebaseHelper
import UIKit

enum ButtonName {
    static let cancel = "cancel"
    static let confirm = "confirm"
    static let delete = "delete"
    static let info = "info"
    static let makeNewMessage = "makeNewMessage"
    static let makeNewProxy = "makeNewProxy"
}

enum Child {
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

enum Color {
    static let blue = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    static let loginButtonBlue = UIColor(red: 53/255, green: 152/255, blue: 217/255, alpha: 1)
}

// todo: String(describing: Type.self)
enum Identifier {
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

enum Setting {
    static let querySize: UInt = 30
}

enum Shared {
    static let auth = Auth.auth()
    static let firebaseApp = FirebaseApp.app()
    static let firebaseHelper = FirebaseHelper(FirebaseDatabase.Database.database().reference())
}

//extension FirebaseHelper {
//    static let main: FirebaseHelper = {
//        FirebaseHelper(FirebaseDatabase.Database.database().reference())
//    }()
//}

extension UILabel {
    static let warningIcon: UILabel = {
        let warningIcon = UILabel()
        warningIcon.font = UIFont.fontAwesome(ofSize: 30)
        warningIcon.text = String.fontAwesomeIcon(name: .exclamationTriangle)
        warningIcon.textColor = .white
        return warningIcon
    }()
}

extension UIStoryboard {
    static let main: UIStoryboard = {
        UIStoryboard(name: "Main", bundle: nil)
    }()
}
