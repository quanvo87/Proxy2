import CFAlertViewController
import Device
import Firebase
import FirebaseHelper
import FontAwesome_swift
import NotificationBannerSwift
import SwiftMessages

var registrationToken: String?

enum Alert {
    static let deleteProxyMessage = (
        title: "Delete Proxy?",
        message: "Your conversations for this proxy will also be deleted."
    )

    static func make(
        title: String? = nil,
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
                             backgroundColor: UIColor? = Color.alertButtonGreen,
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
                                      backgroundColor: UIColor? = Color.alertButtonRed,
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
    static let registrationTokens = "registrationTokens"
    static let timestamp = "timestamp"
    static let unreadMessages = "unreadMessages"
    static let users = "users"
}

enum Color {
    static let alertButtonGreen = UIColor(red: 41/255, green: 191/255, blue: 60/255, alpha: 1)
    static let alertButtonRed = UIColor(red: 252/255, green: 49/255, blue: 59/255, alpha: 1)
    static let blue = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    static let facebookBlue = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1)
    static let facebookBlueShadow = UIColor(red: 39/255, green: 69/255, blue: 132/255, alpha: 1)
    static let logInButtonBlue = UIColor(red: 53/255, green: 152/255, blue: 217/255, alpha: 1)
    static let logInButtonRed = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
    static let logInButtonRedShadow = UIColor(red: 211/255, green: 56/255, blue: 40/255, alpha: 1)
    static let receiverChatBubbleGray = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
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

    static func make(_ fontAwesome: FontAwesome) -> UIImage {
        return UIImage.fontAwesomeIcon(name: fontAwesome, textColor: .white, size: CGSize(width: 100, height: 100))
    }

    static func makeCircle(diameter: CGFloat, color: UIColor = Color.blue) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: rect)
        context?.restoreGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = image {
            return image
        } else {
            return UIImage()
        }
    }
}

enum Label {
    static let check: UILabel = {
        let check = UILabel()
        check.font = UIFont.fontAwesome(ofSize: 45)
        check.text = String.fontAwesomeIcon(name: .checkCircle)
        check.textColor = .white
        return check
    }()

    static let exclamation: UILabel = {
        let exclamation = UILabel()
        exclamation.font = UIFont.fontAwesome(ofSize: 45)
        exclamation.text = String.fontAwesomeIcon(name: .exclamationTriangle)
        exclamation.textColor = .white
        return exclamation
    }()
}

enum Shared {
    static let auth = Auth.auth()
    static let firebaseApp = FirebaseApp.app()
    static let firebaseHelper = FirebaseHelper(FirebaseDatabase.Database.database().reference())
    static let storyboard = UIStoryboard(name: "Main", bundle: nil)

    static let isSmallDevice: Bool = {
        switch Device.size() {
        case .screen3_5Inch:
            return true
        case .screen4Inch:
            return true
        default:
            return false
        }
    }()

    static let decimalNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

enum StatusBar {
    private static let queue = ProxyNotificationBannerQueue()

    static func showErrorBanner(title: String = "Error 😵", subtitle: String) {
        queue.currentBanner = NotificationBanner(
            title: title,
            subtitle: subtitle,
            leftView: Label.exclamation,
            style: .danger
        )
    }

    static func showErrorStatusBarBanner(_ error: Error) {
        let view = MessageView.viewFromNib(layout: .statusLine)
        view.configureTheme(.error)
        view.configureContent(body: "⚠️ " + error.localizedDescription)
        SwiftMessages.show(view: view)
    }

    static func showSuccessBanner(title: String, subtitle: String) {
        queue.currentBanner = NotificationBanner(
            title: title,
            subtitle: subtitle,
            leftView: Label.check,
            style: .success
        )
    }

    // todo: sometimes showing behind status bar
    static func showSuccessStatusBarBanner(_ title: String) {
        queue.currentBanner = StatusBarNotificationBanner(
            title: title,
            style: .success
        )
    }
}
