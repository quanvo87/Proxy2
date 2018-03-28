import CFAlertViewController
import Device
import DynamicColor
import Firebase
import FirebaseHelper
import FontAwesome_swift
import NotificationBannerSwift
import Piano
import SwiftMessages

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

enum Audio {
    static let incomingMessageAudioPlayer = AudioPlayer(soundFileName: "incomingMessage")
    static let outgoingMessageAudioPlayer = AudioPlayer(soundFileName: "outgoingMessage")
}

enum Child {
    static let blockedUsers = "blockedUsers"
    static let convos = "convos"
    static let contacts = "contacts"
    static let dateBlocked = "dateBlocked"
    static let hasUnreadMessage = "hasUnreadMessage"
    static let icon = "icon"
    static let key = "key"
    static let lastMessage = "lastMessage"
    static let messages = "messages"
    static let name = "name"
    static let parentConvoKey = "parentConvoKey"
    static let proxies = "proxies"
    static let proxyKeys = "proxyKeys"
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
    static let chatBubbleGray = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    static let buttonBlue = UIColor(red: 53/255, green: 152/255, blue: 217/255, alpha: 1)
    static let buttonRed = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
    static let facebookBlue = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1)
    static let iOSBlue = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    static let mainThemeDarkBlue = UIColor(hex: 0x2c3e50)
}

enum Constant {
    // swiftlint:disable line_length
    enum URL {
        static let coverr = Foundation.URL(string: "http://coverr.co/")!
        static let icons8 = Foundation.URL(string: "https://icons8.com/")!
        static let privacyPolicy = (
            name: "Privacy Policy",
            url: Foundation.URL(string: "https://app.termly.io/document/privacy-policy-for-mobile-app/a18afe5f-a9a2-4a6d-b090-900905e2ef65")!
        )
        static let termsAndConditions = (
            name: "Terms & Conditions",
            url: Foundation.URL(string: "https://www.websitepolicies.com/policies/view/VxVOCd")!
        )
        static let testDatabase = "https://proxy-fe133-f1159.firebaseio.com/"
    }
    // swiftlint:enable line_length
    static let convoDetailSenderProxyTableViewCell = "ConvoDetailSenderProxyTableViewCell"
    static let isRunningTests = UserDefaults.standard.bool(forKey: "isRunningTests")
    static let tableViewRefreshRate: TimeInterval = 10
}

enum DatabaseOption {
    static let generator = (name: "generator", value: ProxyPropertyGenerator())
    static let makeProxyRetries = (name: "makeProxyRetries", value: 50)
    static let maxMessageSize = (name: "maxMessageSize", value: 20000)
    static let maxNameSize = (name: "maxNameSize", value: 50)
    static let maxProxyCount = (name: "maxProxyCount", value: 30)
    static let querySize: UInt = 30
}

enum DeviceInfo {
    enum FeedbackType {
        case haptic
        case taptic
        case none
    }

    static let feedbackType: FeedbackType = {
        switch Device.version() {
        case .iPhoneX, .iPhone8Plus, .iPhone8, .iPhone7Plus, .iPhone7:
            return .haptic
        case .iPhone6SPlus, .iPhone6S:
            return .taptic
        default:
            return .none
        }
    }()

    static let isSmallDevice: Bool = {
        switch Device.size() {
        case .screen3_5Inch, .screen4Inch:
            return true
        default:
            return false
        }
    }()
}

enum Haptic {
    static func playError() {
        switch DeviceInfo.feedbackType {
        case .haptic:
            Piano.play([.hapticFeedback(.notification(.failure))])
        case .taptic:
            Piano.play([.tapticEngine(.failed)])
        default:
            break
        }
    }

    static func playSuccess() {
        switch DeviceInfo.feedbackType {
        case .haptic:
            Piano.play([.hapticFeedback(.impact(.light))])
        case .taptic:
            Piano.play([.tapticEngine(.peek)])
        default:
            break
        }
    }
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

    static func makeCircle(diameter: CGFloat, color: UIColor = Color.iOSBlue) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: rect)
        context?.restoreGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
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

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

enum Shared {
    static let auth = Auth.auth()
    static let database = Firebase()
    static let firebaseHelper = Constant.isRunningTests ?
        FirebaseHelper(Shared.testDatabaseReference) :
        FirebaseHelper(FirebaseDatabase.Database.database().reference())
    static let testDatabaseReference = FirebaseDatabase.Database.database(url: Constant.URL.testDatabase).reference()
    static let storyboard = UIStoryboard(name: "Main", bundle: nil)
}

enum StatusBar {
    private static let queue = ProxyNotificationBannerQueue()

    static func showErrorBanner(title: String = "Error 😵", subtitle: String) {
        Haptic.playError()
        queue.currentBanner = NotificationBanner(
            title: title,
            subtitle: subtitle,
            leftView: Label.exclamation,
            style: .danger
        )
    }

    static func showErrorStatusBarBanner(_ error: Error) {
        Haptic.playError()
        let view = MessageView.viewFromNib(layout: .statusLine)
        view.configureTheme(.error)
        view.configureContent(body: "⚠️ " + error.localizedDescription)
        SwiftMessages.show(view: view)
    }

    static func showNewMessageBanner(_ convo: Convo) {
        let notificationBanner = NotificationBanner(
            title: convo.receiverDisplayName + " -> " + convo.senderDisplayName,
            subtitle: convo.lastMessage,
            leftView: UIImageView(convo.receiverIcon),
            rightView: UIImageView(convo.senderIcon),
            style: .info
        )
        notificationBanner.onTap = {
            NotificationCenter.default.post(name: .shouldShowConvo, object: nil, userInfo: ["convo": convo])
        }
        queue.currentBanner = notificationBanner
    }

    static func showSuccessBanner(title: String, subtitle: String) {
        Haptic.playSuccess()
        queue.currentBanner = NotificationBanner(
            title: title,
            subtitle: subtitle,
            leftView: Label.check,
            style: .success
        )
    }

    static func showSuccessStatusBarBanner(_ title: String) {
        Haptic.playSuccess()
        NotificationBannerQueue.default.removeAll()
        let statusBarNotificationBanner = StatusBarNotificationBanner(
            title: title,
            style: .success
        )
        statusBarNotificationBanner.haptic = .none
        statusBarNotificationBanner.show()
    }
}
