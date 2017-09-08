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

    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        if let string = NumberFormatter.proxyNumberFormatter.string(from: NSNumber(integerLiteral: Int(num))) {
            return string
        }
        return "-"
    }
}

private extension NumberFormatter {
    static let proxyNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension String {
    static func makePath(_ first: String, _ rest: String...) -> String? {
        return makePath(first, rest)
    }

    static func makePath(_ first: String, _ rest: [String]) -> String? {
        var children = rest
        children.insert(first, at: 0)

        let trimmed = children.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

        for child in trimmed where child == "" || child.contains("//") {
            return nil
        }

        return trimmed.joined(separator: "/")
    }

    func makeBold(withSize size: CGFloat) -> NSMutableAttributedString {
        let boldAttr = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: size)]
        return NSMutableAttributedString(string: self, attributes: boldAttr)
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

extension UITableViewController {
    func goToConvoVC(_ convo: Convo) {
        guard let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController else { return }
        convoVC.convo = convo
        navigationController?.pushViewController(convoVC, animated: true)
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
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
