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
            let _you = NSMutableAttributedString(string: you, attributes: boldAttr)
            let _them = NSAttributedString(string: ", \(them)")
            _you.appendAttributedString(_them)
            return _you
        } else {
            let blueAttr = [NSForegroundColorAttributeName: UIColor(red: 0, green: 122, blue: 255)]
            return NSAttributedString(string: nickname, attributes: blueAttr)
        }
    }
}

extension String {
    
    func nicknameFormatted() -> String {
        return self == "" ? "" : " - \"\(self)\""
    }
    
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
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}