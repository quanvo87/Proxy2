import FirebaseDatabase
import paper_onboarding
import SkyFloatingLabelTextField
import Spring

extension CALayer {
    func stopAnimating() {
        removeAllAnimations()
        shadowColor = UIColor.clear.cgColor
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    var parentConvoKey: String? {
        return self["gcm.notification.parentConvoKey"] as? String ?? nil
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
            string: convo.receiverDisplayName
        )
        let sender = NSMutableAttributedString(
            string: ", " + convo.senderDisplayName,
            attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray]
        )
        receiver.append(sender)
        self.init(attributedString: receiver)
    }
}

extension Notification.Name {
    static let didEnterConvo = Notification.Name("didEnterConvo")
    static let didLeaveConvo = Notification.Name("didLeaveConvo")
    static let shouldShowConvo = Notification.Name("shouldShowConvo")
}

extension OnboardingItemInfo {
    init(title: String, description: String, pageIcon: UIImage) {
        self.init(
            informationImage: UIImage(),
            title: title,
            description: description,
            pageIcon: pageIcon,
            color: .clear,
            titleColor: .white,
            descriptionColor: .white,
            titleFont: UIFont.systemFont(ofSize: 20),
            descriptionFont: UIFont.systemFont(ofSize: 14))
    }
}

extension SkyFloatingLabelTextFieldWithIcon {
    func setupAsEmailTextField() {
        setup()
        iconFont = UIFont.fontAwesome(ofSize: 15)
        iconText = String.fontAwesomeIcon(name: .envelope)
        keyboardType = .emailAddress
        placeholder = "Email"
        returnKeyType = .next
        textContentType = .emailAddress
    }

    func setupAsPasswordTextField() {
        setup()
        iconFont = UIFont.fontAwesome(ofSize: 20)
        iconText = String.fontAwesomeIcon(name: .lock)
        isSecureTextEntry = true
        placeholder = "Password"
        returnKeyType = .go
        textContentType = .password
    }

    func setup() {
        clearButtonMode = .whileEditing
        selectedIconColor = Color.logInButtonBlue
        selectedLineColor = Color.logInButtonBlue
        selectedTitleColor = Color.logInButtonBlue
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
    var withoutWhiteSpacesAndNewLines: String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getFirstNChars(_ n: Int) -> String {
        guard count >= n else {
            return ""
        }
        return String(self[..<index(startIndex, offsetBy: n)])
    }
}

extension UIActivityIndicatorView {
    convenience init(_ view: UIView, style: UIActivityIndicatorViewStyle = .gray) {
        self.init(activityIndicatorStyle: style)
        center = view.center
        view.addSubview(self)
    }

    func startAnimatingAndBringToFront() {
        startAnimating()
        superview?.bringSubview(toFront: self)
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

extension UIImageView {
    convenience init(_ iconName: String, frame: CGRect = CGRect(x: 0, y: 0, width: 30, height: 30)) {
        self.init(frame: frame)
        image = UIImage(named: iconName)
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
    // todo: test
    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        guard let string = Constant.decimalNumberFormatter.string(from: NSNumber(integerLiteral: Int(num))) else {
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
    func showConvoViewController(_ convo: Convo) {
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
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            guard let nickname = alert?.textFields?[0].text else {
                return
            }
            let trimmed = nickname.trimmed
            if !(nickname != "" && trimmed == "") {
                database.setNickname(to: nickname, for: proxy) { error in
                    if let error = error {
                        StatusBar.showErrorStatusBarBanner(error)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showIconPickerViewController(_ proxy: Proxy) {
        let iconPickerViewController = IconPickerViewController(proxy: proxy)
        let navigationController = UINavigationController(rootViewController: iconPickerViewController)
        present(navigationController, animated: true)
    }

    func showProxyViewController(_ proxy: Proxy) {
        let proxyViewController = ProxyViewController(proxy: proxy)
        navigationController?.pushViewController(proxyViewController, animated: true)
    }

    func showWebViewController(title: String, urlString: String) {
        let webViewController = WebViewController(title: title, urlString: urlString)
        let navigationController = UINavigationController(rootViewController: webViewController)
        present(navigationController, animated: true)
    }
}
