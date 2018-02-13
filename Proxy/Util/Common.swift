import Firebase
import FirebaseHelper
import NotificationBannerSwift
import SkyFloatingLabelTextField
import Spring

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

extension Auth {
    static let auth: Auth = {
        Auth.auth()
    }()
}

// https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    func isWithinRangeOf(_ rhs: Double, range: Double = 1) -> Bool {
        return (self - range)...(self + range) ~= rhs
    }
}

extension FirebaseApp {
    static let app: FirebaseApp? = {
        FirebaseApp.app()
    }()
}

extension FirebaseHelper {
    static let main: FirebaseHelper = {
        FirebaseHelper(FirebaseDatabase.Database.database().reference())
    }()
}

extension DataSnapshot {
    func toConvosArray(proxyKey: String?) -> [Convo] {
        return children.flatMap {
            guard
                let data = $0 as? DataSnapshot,
                let convo = try? Convo(data) else {
                    return nil
            }
            if let proxyKey = proxyKey {
                if convo.senderProxyKey == proxyKey {
                    return convo
                } else {
                    return nil
                }
            } else {
                return convo
            }
        }
    }

    var toMessagesArray: [Message] {
        return children.flatMap {
            guard
                let data = $0 as? DataSnapshot,
                let message = try? Message(data) else {
                    return nil
            }
            return message
        }
    }

    var toProxiesArray: [Proxy] {
        return children.flatMap {
            guard
                let data = $0 as? DataSnapshot,
                let proxy = try? Proxy(data) else {
                    return nil
            }
            return proxy
        }
    }
}

extension Int {
    var asStringWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }

    var random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension SkyFloatingLabelTextFieldWithIcon {
    func setupAsEmailTextField() {
        clearButtonMode = .whileEditing
        iconFont = UIFont.fontAwesome(ofSize: 15)
        iconText = String.fontAwesomeIcon(name: .envelope)
        keyboardType = .emailAddress
        placeholder = "Email"
        returnKeyType = .next
        selectedIconColor = .loginButtonBlue
        selectedLineColor = .loginButtonBlue
        selectedTitleColor = .loginButtonBlue
        textContentType = .emailAddress
    }

    func setupAsPasswordTextField() {
        clearButtonMode = .whileEditing
        iconFont = UIFont.fontAwesome(ofSize: 20)
        iconText = String.fontAwesomeIcon(name: .lock)
        isSecureTextEntry = true
        placeholder = "Password"
        returnKeyType = .go
        selectedIconColor = .loginButtonBlue
        selectedLineColor = .loginButtonBlue
        selectedTitleColor = .loginButtonBlue
        textContentType = .password
    }
}

extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension UIBarButtonItem {
    convenience init(target: Any?,
                     action: Selector,
                     frame: CGRect = Setting.navBarButtonCGRect,
                     image: UIImage?) {
        self.init()
        let button = SpringButton(type: .custom)
        button.addTarget(
            target,
            action: action,
            for: .touchUpInside
        )
        button.frame = frame
        button.setImage(image, for: .normal)
        customView = button
    }

    func animate(loop: Bool = false) {
        customView?.layer.stopAnimating()
        (customView as? SpringButton)?.morph(loop: loop)
        if loop {
            customView?.addGlow()
        }
    }

    func stopAnimating() {
        customView?.layer.stopAnimating()
    }
}

extension UIColor {
    static let blue: UIColor = {
        UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    }()

    static let loginButtonBlue: UIColor = {
        return UIColor(red: 53/255, green: 152/255, blue: 217/255, alpha: 1)
    }()
}

extension UIImage {
    static let cancel: UIImage? = {
        UIImage(named: "cancel")
    }()

    static let confirm: UIImage? = {
        UIImage(named: "confirm")
    }()

    static let delete: UIImage? = {
        UIImage(named: "delete")
    }()

    static let info: UIImage? = {
        UIImage(named: "info")
    }()

    static let makeNewMessage: UIImage? = {
        UIImage(named: "makeNewMessage")
    }()

    static let makeNewProxy: UIImage? = {
        UIImage(named: "makeNewProxy")
    }()

    static func makeCircle(diameter: CGFloat, color: UIColor = .blue) -> UIImage? {
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

extension UILabel {
    static let warningIcon: UILabel = {
        let warningIcon = UILabel()
        warningIcon.font = UIFont.fontAwesome(ofSize: 30)
        warningIcon.text = String.fontAwesomeIcon(name: .exclamationTriangle)
        warningIcon.textColor = .white
        return warningIcon
    }()
}

extension UINavigationBar {
    convenience init(target: Any?, action: Selector, width: CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: 40))
        let item = UINavigationItem()
        let image = UIImage.fontAwesomeIcon(name: .angleDown, textColor: .blue, size: CGSize(width: 30, height: 30))
        item.rightBarButtonItem = UIBarButtonItem(target: target, action: action, image: image)
        pushItem(item, animated: false)
    }
}

extension UIStoryboard {
    static let main: UIStoryboard = {
        UIStoryboard(name: "Main", bundle: nil)
    }()
}

extension UITableView {
    func setDelaysContentTouchesForScrollViews(value: Bool = false) {
        for case let scrollView as UIScrollView in self.subviews {
            scrollView.delaysContentTouches = value
        }
    }
}

extension UIViewController {
    func showAlert(title: String?, message: String?, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    func showConvoController(_ convo: Convo) {
        let convoViewController = ConvoViewController(convo: convo)
        navigationController?.pushViewController(convoViewController, animated: true)
    }

    func showEditProxyNicknameAlert(_ proxy: Proxy, database: Database = Firebase()) {
        let alert = UIAlertController(title: "Edit Nickname",
                                      message: "Only you see your nickname.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = proxy.nickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let nickname = alert?.textFields?[0].text else {
                return
            }
            let trimmed = nickname.trimmed
            if !(nickname != "" && trimmed == "") {
                database.setNickname(to: nickname, for: proxy) { error in
                    if let error = error {
                        self?.showErrorAlert(error)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showErrorAlert(_ error: Error, completion: (() -> Void)? = nil) {
        if let error = error as? ProxyError {
            showAlert(title: error.alertFields.title,
                      message: error.alertFields.description,
                      completion: completion)
        } else {
            showAlert(title: ProxyError.unknown.alertFields.title,
                      message: error.localizedDescription,
                      completion: completion)
        }
    }

    func showErrorBanner(_ error: Error) {
        var title = ""
        var subTitle = ""
        if let error = error as? ProxyError {
            title = error.alertFields.title
            subTitle = error.alertFields.description
        } else {
            title = ProxyError.unknown.alertFields.title
            subTitle = error.localizedDescription
        }
        NotificationBannerQueue.default.removeAll()
        let banner = NotificationBanner(
            attributedTitle: NSAttributedString(string: title),
            attributedSubtitle: NSAttributedString(string: subTitle),
            leftView: UILabel.warningIcon,
            style: .danger
        )
        banner.haptic = .light
        banner.show()
    }

    func showIconPickerController(_ proxy: Proxy) {
        let iconPickerViewController = IconPickerViewController(proxy: proxy)
        let navigationController = UINavigationController(rootViewController: iconPickerViewController)
        present(navigationController, animated: true)
    }

    func showProxyController(_ proxy: Proxy) {
        let proxyViewController = ProxyViewController(proxy: proxy)
        navigationController?.pushViewController(proxyViewController, animated: true)
    }
}

private extension CALayer {
    func stopAnimating() {
        removeAllAnimations()
        shadowColor = UIColor.clear.cgColor
    }
}

private extension SpringButton {
    func morph(loop: Bool = false) {
        animation = "morph"
        curve = "spring"
        duration = loop ? 1.2 : 0.8
        repeatCount = loop ? .infinity : 0
        animate()
    }
}

private extension UIView {
    func addGlow(color: CGColor = UIColor.blue.cgColor) {
        layer.shadowColor = color
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.9
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }
}
