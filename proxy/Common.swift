//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

typealias Success = Bool

enum Result {
    case success(Any)
    case failure(Error)
}

extension Array where Element: UITableViewCell {
    var incrementedTags: Void {
        _ = self.map { $0.tag.increment() }
    }
}

extension DataSnapshot {
    func toConvos() -> [Convo] {
        var convos = [Convo]()
        for child in self.children {
            if  let snapshot = child as? DataSnapshot,
                let convo = Convo(snapshot.value as AnyObject),
                !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos
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

    var asLabel: String {
        return self == 0 ? "" : String(self)
    }

    var shortForm: String {
        var num = Double(self)
        let sign = ((num < 0) ? "-" : "" )

        num = fabs(num)

        if num < 1000000000.0 {
            if let string = NumberFormatter.proxyNumberFormatter.string(from: NSNumber(integerLiteral: Int(num))) {
                return string
            }
            return "-"
        }

        let exp = Int(log10(num) / 3.0 )

        let units = ["K","M","G","T","P","E"]

        let roundedNum = round(10 * num / pow(1000.0,Double(exp))) / 10

        return "\(sign)\(roundedNum)\(units[exp-1])"
    }
}

extension NumberFormatter {
    static let proxyNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension String {
    func makeBold(withSize size: CGFloat) -> NSMutableAttributedString {
        let boldAttr = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: size)]
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
