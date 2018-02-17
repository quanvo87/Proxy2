import CFAlertViewController
import Firebase
import FirebaseHelper
import NotificationBannerSwift

enum Alert {
    static let deleteProxyMessage = (
        title: "Delete Proxy?",
        message: "Your conversations for this proxy will also be deleted."
    )

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

    static func makeAlert(title: String? = nil,
                          titleColor: UIColor? = nil,
                          message: String? = nil,
                          messageColor: UIColor? = nil,
                          textAlignment: NSTextAlignment = .left,
                          preferredStyle: CFAlertViewController.CFAlertControllerStyle = .alert,
                          headerView: UIView? = nil,
                          footerView: UIView? = nil,
                          handler: CFAlertViewController.CFAlertViewControllerDismissBlock? = nil) -> CFAlertViewController {
        return CFAlertViewController(
            title: title,
            titleColor: titleColor,
            message: message,
            messageColor: messageColor,
            textAlignment: textAlignment,
            preferredStyle: preferredStyle,
            headerView: headerView,
            footerView: footerView,
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

enum Identifier {
    static let convoDetailSenderProxyTableViewCell = "ConvoDetailSenderProxyTableViewCell"
}

enum Image {
    static let cancel = UIImage(named: "cancel")
    static let confirm = UIImage(named: "confirm")
    static let delete = UIImage(named: "delete")
    static let info = UIImage(named: "info")
    static let makeNewMessage = UIImage(named: "makeNewMessage")
    static let makeNewProxy = UIImage(named: "makeNewProxy")

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
    static let storyboard = UIStoryboard(name: "Main", bundle: nil)
}
