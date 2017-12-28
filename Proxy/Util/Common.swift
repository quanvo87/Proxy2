import Firebase
import UIKit

typealias Success = Bool

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

extension DispatchQueue {
    static let queue: DispatchQueue = {
        return DispatchQueue(label: "proxyQueue")
    }()
}

extension Double {
    var asTimeAgo: String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
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

extension String {
    func getFirstNChars(_ n: Int) -> String {
        guard self.count >= n else {
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
        let button = UIButton(type: .custom)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.frame = Setting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName), for: .normal)
        return UIBarButtonItem(customView: button)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    static var blue: UIColor {
        return UIColor(red: 0, green: 122, blue: 255)
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
    func showConvoViewController(convo: Convo, unreadMessagesManager: UnreadMessagesManaging?) {
        pushViewController(ConvoViewController(convo: convo, unreadMessagesManager: unreadMessagesManager), animated: true)
    }
}

extension UINavigationItem {
    func disableRightBarButtonItem(atIndex index: Int) {
        guard let item = self.rightBarButtonItems?[safe: index] else {
            return
        }
        item.isEnabled = false
    }

    func enableRightBarButtonItem(atIndex index: Int) {
        guard let item = self.rightBarButtonItems?[safe: index] else {
            return
        }
        item.isEnabled = true
    }
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

extension UIViewController {
    func showAlert(_ title: String?, message: String?, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (_) in
            completion?()
        })
        present(alert, animated: true)
    }

    func showEditProxyNicknameAlert(_ proxy: Proxy) {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = proxy.nickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let nickname = alert.textFields?[0].text else {
                return
            }
            let trimmed = nickname.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            if !(nickname != "" && trimmed == "") {
                DBProxy.setNickname(to: nickname, forProxy: proxy) { (error) in
                    if let error = error, case .inputTooLong = error {
                        self.showAlert("Nickname Too Long", message: "Please try a shorter nickname.") {
                            self.showEditProxyNicknameAlert(proxy)
                        }
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showIconPickerController(_ proxy: Proxy) {
        let viewController = IconPickerViewController(proxy)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    func showProxyController(proxy: Proxy, unreadMessagesManager: UnreadMessagesManaging?) {
        navigationController?.pushViewController(ProxyViewController(proxy: proxy, unreadMessagesManager: unreadMessagesManager), animated: true)
    }
}

private extension NumberFormatter {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
