import Firebase
import Spring
import UIKit

enum FirstResponder {
    case receiverTextField
    case newMessageTextView
}

extension Auth {
    static let auth: Auth = {
        Auth.auth()
    }()
}

extension CALayer {
    func stopAnimating() {
        removeAllAnimations()
        shadowColor = UIColor.clear.cgColor
    }
}

// https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    var asTimeAgo: String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
    }

    func isWithinRangeOf(_ rhs: Double, range: Double = 1) -> Bool {
        return (self - range)...(self + range) ~= rhs
    }
}

extension FirebaseApp {
    static let app: FirebaseApp? = {
        return FirebaseApp.app()
    }()
}

extension DataSnapshot {
    var asNumberLabel: String {
        if let number = self.value as? UInt {
            return number.asStringWithCommas
        } else {
            return "-"
        }
    }

    var asMessagesArray: [Message] {
        var messages = [Message]()
        for child in self.children {
            guard let data = child as? DataSnapshot else {
                continue
            }
            if let message = Message(data) {
                messages.append(message)
            }
        }
        return messages
    }

    func toConvosArray(uid: String, proxyKey: String?) -> [Convo] {
        var convos = [Convo]()
        for child in self.children {
            guard let data = child as? DataSnapshot else {
                return convos
            }
            guard let convo = Convo(data) else {
                continue
            }
            if let proxyKey = proxyKey {
                if convo.senderProxyKey == proxyKey {
                    convos.append(convo)
                }
            } else {
                convos.append(convo)
            }
        }
        return convos
    }

    func toProxiesArray(uid: String) -> [Proxy] {
        var proxies = [Proxy]()
        for child in self.children {
            guard let data = child as? DataSnapshot else {
                return proxies
            }
            guard let proxy = Proxy(data) else {
                continue
            }
            proxies.append(proxy)
        }
        return proxies
    }
}

extension Int {
    var asLabel: String {
        return self == 0 ? "" : String(self)
    }

    var asStringWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }

    var random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension NSAttributedString {
    static func makeConvoTitle(_ convo: Convo) -> NSAttributedString {
        let grayAttribute = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        let receiver = NSMutableAttributedString(string: (convo.receiverNickname == "" ? convo.receiverProxyName : convo.receiverNickname) + ", ")
        let sender = NSMutableAttributedString(string: convo.senderNickname == "" ? convo.senderProxyName : convo.senderNickname,
                                               attributes: grayAttribute)
        receiver.append(sender)
        return receiver
    }
}

extension SpringButton {
    func morph(loop: Bool = false) {
        animation = "morph"
        curve = "spring"
        duration = loop ? 1.2 : 0.8
        repeatCount = loop ? .infinity : 0
        animate()
    }
}

extension String {
    var noWhiteSpaces: String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getFirstNChars(_ n: Int) -> String {
        guard count >= n else {
            return ""
        }
        return String(self[..<self.index(self.startIndex, offsetBy: n)])
    }

    func makeBold(withSize size: CGFloat) -> NSMutableAttributedString {
        let boldAttr = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: size)]
        return NSMutableAttributedString(string: self, attributes: boldAttr)
    }
}

extension UIBarButtonItem {
    static func make(target: Any?, action: Selector, imageName: String) -> UIBarButtonItem {
        let button = SpringButton(type: .custom)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.frame = Setting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName), for: .normal)
        return UIBarButtonItem(customView: button)
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
    static var blue: UIColor {
        return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    }
}

extension UIImage {
    static func make(name: String, completion: @escaping (UIImage) -> Void) {
        if let image = UIImage(named: name) {
            completion(image)
        }
    }

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

extension UInt {
    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        if let string = NumberFormatter.decimal.string(from: NSNumber(integerLiteral: Int(num))) {
            return string
        }
        return "-"
    }
}

extension UINavigationController {

}

extension UIStoryboard {
    static let main: UIStoryboard = {
        return UIStoryboard(name: "Main", bundle: nil)
    }()
}

extension UITableView {
    func setDelaysContentTouchesForScrollViews(value: Bool = false) {
        for case let scrollView as UIScrollView in self.subviews {
            scrollView.delaysContentTouches = value
        }
    }
}

extension UIView {
    func addGlow(color: CGColor = UIColor.blue.cgColor) {
        layer.shadowColor = color
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.9
        layer.shadowOffset = .zero
        layer.masksToBounds = false
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

    func showConvoController(convo: Convo,
                             presenceManager: PresenceManaging?,
                             unreadMessagesManager: UnreadMessagesManaging?) {
        navigationController?.pushViewController(ConvoViewController(convo: convo,
                                                                     presenceManager: presenceManager,
                                                                     unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }

    func showEditProxyNicknameAlert(_ proxy: Proxy, database: DatabaseType = FirebaseDatabase()) {
        let alert = UIAlertController(title: "Edit Nickname",
                                      message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField { (textField) in
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
                database.setNickname(to: nickname, for: proxy) { (error) in
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
                      message: ProxyError.unknown.alertFields.description,
                      completion: completion)
        }
    }

    func showIconPickerController(_ proxy: Proxy) {
        let viewController = IconPickerViewController(proxy: proxy)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    func showProxyController(proxy: Proxy,
                             presenceManager: PresenceManaging?,
                             unreadMessagesManager: UnreadMessagesManaging?) {
        navigationController?.pushViewController(ProxyViewController(proxy: proxy,
                                                                     presenceManager: presenceManager,
                                                                     unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }
}

private extension NumberFormatter {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
