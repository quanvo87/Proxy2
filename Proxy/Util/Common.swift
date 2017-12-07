import Firebase
import FirebaseAuth
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

    var isNewProxyDate: Bool {
        let secondsAgo = -Date(timeIntervalSince1970: self).timeIntervalSinceNow
        return secondsAgo < Setting.newProxyBadgeDuration
    }
}

extension FirebaseApp {
    static let app: FirebaseApp? = {
        return FirebaseApp.app()
    }()
}

extension Int {
    var asLabel: String {
        return self == 0 ? "" : String(self)
    }

    var asLabelWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }

    var random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension String {
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
    static func makeImage(named image: String, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.queue.async {
            completion(UIImage(named: image))
        }
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
    func showConvoViewController(_ convo: Convo) {
        guard let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController else {
            return
        }
        viewController.convo = convo
        pushViewController(viewController, animated: true)
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

extension UIViewController {
    func showAlert(_ title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showIconPicker(_ proxy: Proxy) {
        let viewController = IconPickerViewController(proxy)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }
}

private extension NumberFormatter {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
