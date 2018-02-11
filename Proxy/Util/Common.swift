import Firebase
import FirebaseHelper
import PureLayout
import Spring
import SwiftyButton

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

extension CustomPressableButton {
    func configure(text: String,
                   asFacebookButton: Bool = false,
                   colors: ColorSet? = nil,
                   fontSize: CGFloat? = nil) {
        cornerRadius = 5
        shadowHeight = 5

        if asFacebookButton {
            let icon = UILabel()
            icon.font = UIFont.fontAwesome(ofSize: 20)
            icon.text = String.fontAwesomeIcon(name: .facebook)
            icon.textColor = .white

            self.contentView.addSubview(icon)

            icon.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(
                    top: 10, left: 15, bottom: 10, right: 0
                ),
                excludingEdge: .right
            )

            self.colors = .init(button: .facebookBlue, shadow: .facebookDarkBlue)
        }

        if let colors = colors {
            self.colors = colors
        }

        let label = UILabel()

        if let fontSize = fontSize {
            label.font = UIFont.systemFont(ofSize: fontSize)
        }

        label.text = text
        label.textColor = .white

        contentView.addSubview(label)

        label.autoCenterInSuperview()
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

extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
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

    static var facebookBlue: UIColor {
        return UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1)
    }

    static var facebookDarkBlue: UIColor {
        return UIColor(red: 39/255, green: 69/255, blue: 132/255, alpha: 1)
    }
}

extension UIImage {
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
