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
    
    func convoTitle(nickname: String, you: String, them: String) -> NSAttributedString {
        if nickname == "" {
            let boldAttr = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]
            let _you = NSMutableAttributedString(string: ", \(you)", attributes: boldAttr)
            let _them = NSMutableAttributedString(string: them)
            _them.appendAttributedString(_you)
            return _them
        } else {
            let blueAttr = [NSForegroundColorAttributeName: UIColor().blue()]
            return NSAttributedString(string: nickname, attributes: blueAttr)
        }
    }
}

extension String {
    
    func lastMessageWithTimestamp(interval: Double) -> String {
        var lastMessage = self
        let timestamp = interval.timeAgoFromTimeInterval()
        if lastMessage == "" {
            if timestamp == "Just now" {
                lastMessage = "Created just now."
            } else {
                lastMessage = "Created \(timestamp) ago."
            }
        }
        return lastMessage
    }
    
    func nicknameFormatted() -> NSAttributedString {
        if self == "" {
            return NSAttributedString(string: "")
        } else {
            let blueAttr = [NSForegroundColorAttributeName: UIColor().blue()]
            let dash = NSMutableAttributedString(string: " - ")
            let nickname = NSAttributedString(string: "\"\(self)\"", attributes: blueAttr)
            dash.appendAttributedString(nickname)
            return dash
        }
    }
    
    func makeBold() -> NSAttributedString {
        let boldAttr = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]
        return NSAttributedString(string: self, attributes: boldAttr)
    }
}

extension Double {
    
    func timeAgoFromTimeInterval() -> String {
        let date = NSDate(timeIntervalSince1970: self)
        return timeAgoSince(date)
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