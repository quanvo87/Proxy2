import FirebaseDatabase
import NotificationBannerSwift
import SkyFloatingLabelTextField
import Spring

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

extension CALayer {
    func stopAnimating() {
        removeAllAnimations()
        shadowColor = UIColor.clear.cgColor
    }
}

extension Double {
    var asTimeAgo: String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let this = Date(timeIntervalSince1970: self)
        let now = Date()
        let earliest = now < this ? now : this
        let latest = earliest == now ? this : now
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)

        if components.year! > 0 {
            return "\(components.year!)y"
        } else if components.month! > 0 {
            return "\(components.month!)mo"
        } else if components.weekOfYear! > 0 {
            return "\(components.weekOfYear!)w"
        } else if components.day! > 0 {
            return "\(components.day!)d"
        } else if components.hour! > 0 {
            return "\(components.hour!)h"
        } else if components.minute! > 0 {
            return "\(components.minute!)m"
        } else if components.second! >= 3 {
            return "\(components.second!)s"
        } else {
            return "Just now"
        }
    }

    func isWithinRangeOf(_ rhs: Double, range: Double = 1) -> Bool {
        return (self - range)...(self + range) ~= rhs
    }
}

extension DataSnapshot {
    var asNumberLabel: String {
        if let number = self.value as? UInt {
            return number.asStringWithCommas
        } else {
            return "-"
        }
    }

    func asConvosArray(proxyKey: String?) -> [Convo] {
        return children.flatMap {
            guard let data = $0 as? DataSnapshot, let convo = try? Convo(data) else {
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

    var asMessagesArray: [Message] {
        return children.flatMap {
            guard let data = $0 as? DataSnapshot, let message = try? Message(data) else {
                return nil
            }
            return message
        }
    }

    var asProxiesArray: [Proxy] {
        return children.flatMap {
            guard let data = $0 as? DataSnapshot, let proxy = try? Proxy(data) else {
                return nil
            }
            return proxy
        }
    }
}

extension Int {
    var asBadgeValue: String? {
        return self == 0 ? nil : String(self)
    }

    var asStringWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }

    var random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension NSAttributedString {
    convenience init(_ convo: Convo) {
        let receiver = NSMutableAttributedString(
            string: (convo.receiverNickname == "" ? convo.receiverProxyName : convo.receiverNickname) + ", "
        )
        let sender = NSMutableAttributedString(
            string: convo.senderNickname == "" ? convo.senderProxyName : convo.senderNickname,
            attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray]
        )
        receiver.append(sender)
        self.init(attributedString: receiver)
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
        selectedIconColor = Color.loginButtonBlue
        selectedLineColor = Color.loginButtonBlue
        selectedTitleColor = Color.loginButtonBlue
        textContentType = .emailAddress
    }

    func setupAsPasswordTextField() {
        clearButtonMode = .whileEditing
        iconFont = UIFont.fontAwesome(ofSize: 20)
        iconText = String.fontAwesomeIcon(name: .lock)
        isSecureTextEntry = true
        placeholder = "Password"
        returnKeyType = .go
        selectedIconColor = Color.loginButtonBlue
        selectedLineColor = Color.loginButtonBlue
        selectedTitleColor = Color.loginButtonBlue
        textContentType = .password
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

    func getFirstNChars(_ n: Int) -> String {
        guard count >= n else {
            return ""
        }
        return String(self[..<index(startIndex, offsetBy: n)])
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension UIBarButtonItem {
    convenience init(target: Any?,
                     action: Selector,
                     frame: CGRect = CGRect(x: 0, y: 0, width: 30, height: 30),
                     image: UIImage?) {
        self.init()
        let button = SpringButton(type: .custom)
        button.addTarget(target, action: action, for: .touchUpInside)
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

extension UINavigationBar {
    convenience init(target: Any?, action: Selector, width: CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: 40))
        let item = UINavigationItem()
        let image = UIImage.fontAwesomeIcon(
            name: .angleDown,
            textColor: Color.blue,
            size: CGSize(width: 30, height: 30)
        )
        item.rightBarButtonItem = UIBarButtonItem(target: target, action: action, image: image)
        pushItem(item, animated: false)
    }
}

extension UInt {
    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        guard let string = Shared.decimalNumberFormatter.string(from: NSNumber(integerLiteral: Int(num))) else {
            return "-"
        }
        return string
    }
}

extension UILabel {
    convenience init(text: String,
                     font: UIFont? = nil,
                     textColor: UIColor = .white) {
        self.init()
        if let font = font {
            self.font = font
        }
        self.text = text
        self.textColor = textColor
    }
}

extension UITableView {
    func setDelaysContentTouchesForScrollViews(value: Bool = false) {
        for case let scrollView as UIScrollView in subviews {
            scrollView.delaysContentTouches = value
        }
    }
}

extension UIView {
    func addGlow(color: CGColor = Color.blue.cgColor) {
        layer.shadowColor = color
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.9
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }
}

extension UIViewController {
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
                        self?.showErrorBanner(error)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
            leftView: Label.warningIcon,
            style: .danger
        )
        banner.haptic = .light
        banner.show(on: self.navigationController)
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
