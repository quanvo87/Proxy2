//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

extension UIViewController {
    func showAlert(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(dismissAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func convoTitle(convoNickname: String, proxyNickname: String, you: String, them: String) -> NSAttributedString {
        let bold = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]
        let blue = [NSForegroundColorAttributeName: UIColor().blue()]
        let gray = [NSForegroundColorAttributeName: UIColor.grayColor()]
        let comma = NSAttributedString(string: ", ")
        var first: NSMutableAttributedString
        var second: NSAttributedString
        if convoNickname == "" {
            first = NSMutableAttributedString(string: them, attributes: bold)
        } else {
            first = NSMutableAttributedString(string: convoNickname, attributes: bold)
            first.addAttributes(blue, range: NSRange(location: 0, length: first.length))
        }
        if proxyNickname == "" {
            second = NSAttributedString(string: you, attributes: gray)
        } else {
            second = NSAttributedString(string: proxyNickname, attributes: blue)
        }
        first.appendAttributedString(comma)
        first.appendAttributedString(second)
        return first
    }
}

extension String {
    func lastMessageWithTimestamp(interval: Double) -> String {
        var lastMessage = self
        let timestamp = interval.timeAgoFromTimeInterval()
        let secondsAgo = -NSDate(timeIntervalSince1970: interval).timeIntervalSinceNow
        if lastMessage == "" {
            if timestamp == "Just now" {
                lastMessage = "Created just now."
            } else if secondsAgo < 60 * 60 * 24 {
                lastMessage = "Created \(timestamp) ago."
            } else {
                lastMessage = "Created \(timestamp)."
            }
        }
        return lastMessage
    }
    
    func nicknameFormatted() -> NSAttributedString {
        if self == "" {
            return NSAttributedString(string: "")
        } else {
            let blueAttr = [NSForegroundColorAttributeName: UIColor().blue()]
            return NSAttributedString(string: self, attributes: blueAttr)
        }
    }
    
    func makeBold() -> NSAttributedString {
        let boldAttr = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]
        return NSAttributedString(string: self, attributes: boldAttr)
    }
}

extension Double {
    func timeAgoFromTimeInterval() -> String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
    }
}

extension Int {
    func unreadFormatted() -> String {
        return self == 0 ? "" : String(self)
    }
    
    func unreadTitleSuffix() -> String {
        return self == 0 ? "" : "(\(self))"
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
    
    func blue() -> UIColor {
        return UIColor(red: 0, green: 122, blue: 255)
    }
}