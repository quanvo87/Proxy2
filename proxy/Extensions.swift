//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

extension UIView {
    // Returns a  NSAttributedString that can be used for a convo's title.
    // Prioritizes nicknames if possible, over proxy names.
    // Applies formatting based on parameter.
    func getConvoTitle(receiverNickname: String, senderNickname: String, you: String, them: String, size: CGFloat, navBar: Bool) -> NSAttributedString {
        let _size = [NSFontAttributeName: UIFont.systemFontOfSize(size)]
        let bold = [NSFontAttributeName: UIFont.boldSystemFontOfSize(size)]
        let blue = [NSForegroundColorAttributeName: UIColor().blue()]
        let gray = [NSForegroundColorAttributeName: UIColor.grayColor()]
        
        var first: NSMutableAttributedString
        var second: NSMutableAttributedString
        
        let _coma = navBar == true ? " &\n" : ", "
        let comma = NSAttributedString(string: _coma, attributes: _size)
        
        if receiverNickname == "" {
            first = NSMutableAttributedString(string: them, attributes: bold)
        } else {
            first = NSMutableAttributedString(string: receiverNickname, attributes: bold)
            first.addAttributes(blue, range: NSRange(location: 0, length: first.length))
        }
        
        if senderNickname == "" {
            second = NSMutableAttributedString(string: you, attributes: gray)
        } else {
            second = NSMutableAttributedString(string: senderNickname, attributes: blue)
        }
        second.addAttributes(_size, range: NSRange(location: 0, length: second.length))
        
        first.appendAttributedString(comma)
        first.appendAttributedString(second)
        return first
    }
}

extension UIViewController {
    // Shows an alert with the passed in title and string with only an `Ok` button.
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Delete when ready
    // Returns a custom NSAttributedString with the name and nickname.
    func youTitle(name: String, nickname: String) -> NSAttributedString {
        let _name = NSMutableAttributedString(string: name)
        if nickname == "" {
            return _name
        } else {
            let blue = [NSForegroundColorAttributeName: UIColor().blue()]
            let dash = NSAttributedString(string: " - ")
            let _nickname = NSAttributedString(string: " \"\(nickname)\"", attributes: blue)
            _name.appendAttributedString(dash)
            _name.appendAttributedString(_nickname)
            return _name
        }
    }
}

extension Int {
    func toUnreadLabel() -> String {
        return self == 0 ? "" : String(self)
    }
    
    func toTitleSuffix() -> String {
        return self == 0 ? "" : "(\(self))"
    }
}

extension String {
    func makeBold(withSize size: CGFloat) -> NSMutableAttributedString {
        let boldAttr = [NSFontAttributeName: UIFont.boldSystemFontOfSize(size)]
        return NSMutableAttributedString(string: self, attributes: boldAttr)
    }
}

extension Double {
    func toTimeAgo() -> String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
    }
    
    // delete when ready
    func createdAgo() -> String {
        let timestamp = self.toTimeAgo()
        let secondsAgo = -NSDate(timeIntervalSince1970: self).timeIntervalSinceNow
        if timestamp == "Just now" {
            return "Created just now."
        } else if secondsAgo < 60 * 60 * 24 {
            return "Created \(timestamp) ago."
        } else {
            return "Created \(timestamp)."
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
    
    func blue() -> UIColor {
        return UIColor(red: 0, green: 122, blue: 255)
    }
}