import CFAlertViewController
import Firebase
import FirebaseHelper
import NotificationBannerSwift

enum Alert {
    static let deleteProxyMessage = (
        title: "Delete Proxy?",
        message: "Your conversations for this proxy will also be deleted."
    )

    static func makeAlert(title: String?,
                          message: String?,
                          textAlignment: NSTextAlignment = .left,
                          handler: CFAlertViewController.CFAlertViewControllerDismissBlock? = nil) -> CFAlertViewController {
        return CFAlertViewController(
            title: title,
            message: message,
            textAlignment: textAlignment,
            preferredStyle: .alert,
            didDismissAlertHandler: handler
        )
    }

    static func makeOkAction(title: String? = "OK",
                             alignment: CFAlertAction.CFAlertActionAlignment = .justified,
                             backgroundColor: UIColor? = Color.green,
                             textColor: UIColor? = .white,
                             handler: CFAlertAction.CFAlertActionHandlerBlock? = nil) -> CFAlertAction {
        return CFAlertAction(
            title: title,
            style: .Default,
            alignment: alignment,
            backgroundColor: backgroundColor,
            textColor: textColor,
            handler: handler
        )
    }

    static func makeCancelAction(title: String? = "Cancel",
                                 alignment: CFAlertAction.CFAlertActionAlignment = .justified,
                                 backgroundColor: UIColor? = nil,
                                 textColor: UIColor? = nil,
                                 handler: CFAlertAction.CFAlertActionHandlerBlock? = nil) -> CFAlertAction {
        return CFAlertAction(
            title: title,
            style: .Cancel,
            alignment: alignment,
            backgroundColor: backgroundColor,
            textColor: textColor,
            handler: handler
        )
    }

    static func makeDestructiveAction(title: String?,
                                      alignment: CFAlertAction.CFAlertActionAlignment = .justified,
                                      backgroundColor: UIColor? = Color.red,
                                      textColor: UIColor? = .white,
                                      handler: CFAlertAction.CFAlertActionHandlerBlock?) -> CFAlertAction {
        return CFAlertAction(
            title: title,
            style: .Destructive,
            alignment: alignment,
            backgroundColor: backgroundColor,
            textColor: textColor,
            handler: handler
        )
    }
}

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
    static let green = UIColor(red: 41/255, green: 191/255, blue: 60/255, alpha: 1)
    static let red = UIColor(red: 252/255, green: 49/255, blue: 59/255, alpha: 1)
}

enum DatabaseOption {
    static let generator = (name: "generator", value: ProxyPropertyGenerator())
    static let makeProxyRetries = (name: "makeProxyRetries", value: 50)
    static let maxMessageSize = (name: "maxMessageSize", value: 20000)
    static let maxNameSize = (name: "maxNameSize", value: 50)
    static let maxProxyCount = (name: "maxProxyCount", value: 30)
    static let querySize: UInt = 30
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

enum Image {
    static func makeCircle(diameter: CGFloat, color: UIColor = Color.blue) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: rect)
        context?.restoreGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

enum Label {
    static let checkIcon: UILabel = {
        let checkIcon = UILabel()
        checkIcon.font = UIFont.fontAwesome(ofSize: 35)
        checkIcon.text = String.fontAwesomeIcon(name: .checkCircle)
        checkIcon.textColor = .white
        return checkIcon
    }()

    static let warningIcon: UILabel = {
        let warningIcon = UILabel()
        warningIcon.font = UIFont.fontAwesome(ofSize: 35)
        warningIcon.text = String.fontAwesomeIcon(name: .exclamationTriangle)
        warningIcon.textColor = .white
        return warningIcon
    }()
}

enum Shared {
    static let auth = Auth.auth()
    static let firebaseApp = FirebaseApp.app()
    static let firebaseHelper = FirebaseHelper(FirebaseDatabase.Database.database().reference())
}

// todo: separate
enum UI {
    static let storyboard = UIStoryboard(name: "Main", bundle: nil)

    static func showStatusBarNotificationBanner(title: String,
                                                style: BannerStyle = .success,
                                                duration: TimeInterval = 3) {
        NotificationBannerQueue.default.removeAll()
        let banner = StatusBarNotificationBanner(
            attributedTitle: NSAttributedString(string: title),
            style: style
        )
        banner.duration = duration
        banner.show()
    }
}
