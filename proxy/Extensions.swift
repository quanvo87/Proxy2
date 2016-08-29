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
}

extension String {
    
    func isValidEmail() -> Bool {
        return true
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
//        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailTest.evaluateWithObject(self)
    }
    
    func nicknameFormatted() -> String {
        return self == "" ? "" : "\"\(self)\""
    }
    
    func nicknameFormattedWithDash() -> String {
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
}

extension Double {
    
    func timeAgoFromTimeInterval() -> String {
        let date = NSDate(timeIntervalSince1970: 0 - self)
        return timeAgoSince(date)
    }
}

extension Int {
    
    func unreadMessageCountFormatted() -> String {
        return self == 0 ? "" : String(self)
    }
    
    func titleSuffixFromUnreadMessageCount() -> String {
        return self == 0 ? "" : "(\(self))"
    }
}