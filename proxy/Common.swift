//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

typealias Success = Bool

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

typealias AsyncWorkGroupKey = String

extension AsyncWorkGroupKey {
    init() {
        let awgKey = UUID().uuidString
        Shared.shared.asyncWorkGroups[awgKey] = (DispatchGroup(), true)
        self = awgKey
    }

    static func makeAsyncWorkGroupKey() -> AsyncWorkGroupKey {
        return AsyncWorkGroupKey()
    }

    func finishWorkGroup() {
        Shared.shared.asyncWorkGroups.removeValue(forKey: self)
    }

    func startWork() {
        Shared.shared.asyncWorkGroups[self]?.group.enter()
    }

    func finishWork(withResult result: Success) {
        setWorkResult(result)
        Shared.shared.asyncWorkGroups[self]?.group.leave()
    }

    @discardableResult
    func setWorkResult(_ result: Success) -> Success {
        let result = Shared.shared.asyncWorkGroups[self]?.result ?? false && result
        Shared.shared.asyncWorkGroups[self]?.result = result
        return result
    }

    var workResult: Success {
        return Shared.shared.asyncWorkGroups[self]?.result ?? false
    }

    func notify(completion: @escaping () -> Void) {
        Shared.shared.asyncWorkGroups[self]?.group.notify(queue: .main) {
            completion()
        }
    }
}

extension Bool {
    static func &=(lhs: inout Bool, rhs: Bool) {
        lhs = lhs && rhs
    }
}

extension Double {
    var asTimeAgo: String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
    }
}

extension Error {
    var description: String {
        if let proxyError = self as? ProxyError {
            return proxyError.localizedDescription
        }
        return self.localizedDescription
    }
}

extension Int {
    mutating func increment() {
        if self == Int.max {
            self = 0
        } else {
            self += 1
        }
    }

    var asLabelWithParens: String {
        return self == 0 ? "" : " (\(self))"
    }

    var asLabel: String {
        return self == 0 ? "" : String(self)
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

extension UIImage {
    func resize(toNewSize newSize: CGSize, isAspectRatio aspect: Bool) -> UIImage {

        let originalRatio = self.size.width / self.size.height
        let newRatio = newSize.width / newSize.height

        var size = CGSize(width: 0, height: 0)

        if aspect {
            if originalRatio < newRatio {
                size.height = newSize.height
                size.width = newSize.height * originalRatio
            } else {
                size.width = newSize.width
                size.height = newSize.width / originalRatio
            }
        } else {
            size = newSize
        }

        let scale: CGFloat = 1.0
        size.width /= scale
        size.height /= scale

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let resized = resized {
            return resized
        } else {
            return UIImage()
        }
    }
}

extension UIViewController {
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
