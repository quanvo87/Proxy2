import UIKit

typealias Success = Bool

enum Result<T, Error> {
    case success(T)
    case failure(Error)
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

    var isNewProxyDate: Bool {
        let secondsAgo = -Date(timeIntervalSince1970: self).timeIntervalSinceNow
        return secondsAgo < Setting.newProxyBadgeDuration
    }
}

extension Int {
    var asLabel: String {
        return self == 0 ? "" : String(self)
    }

    var asLabelWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }
}

extension MakeNewMessageDelegate where Self: UIViewController {
    func goToMakeNewMessageVC(_ sender: Proxy? = nil) {
        guard let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageVC.delegate = self
        makeNewMessageVC.sender = sender
        let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
        present(navigationController, animated: true)
    }
}

extension String {
    func makeBold(withSize size: CGFloat) -> NSMutableAttributedString {
        let boldAttr = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: size)]
        return NSMutableAttributedString(string: self, attributes: boldAttr)
    }
}

extension UIBarButtonItem {
    static func makeButton(target: Any?, action: Selector, imageName: ButtonName) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.frame = Setting.navBarButtonCGRect
        button.setImage(UIImage(named: imageName.rawValue), for: .normal)
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
        Shared.shared.queue.async {
            completion(UIImage(named: image))
        }
    }
}

extension UInt {
    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        if let string = NumberFormatter.numberFormatter.string(from: NSNumber(integerLiteral: Int(num))) {
            return string
        }
        return "-"
    }
}

extension UINavigationItem {
    func toggleRightBarButtonItem(atIndex index: Int) {
        if let item = self.rightBarButtonItems?[safe: index] {
            item.isEnabled = !item.isEnabled
        }
    }
}

extension UIViewController {
    func goToConvoVC(_ convo: Convo) {
        guard let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController else { return }
        convoVC.convo = convo
        navigationController?.pushViewController(convoVC, animated: true)
    }

    func showAlert(_ title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension NumberFormatter {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
