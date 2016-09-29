//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension Int {
    func toNumberLabel() -> String {
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
}

extension UIImage {
    func resize(toNewSize newSize: CGSize, isAspectRatio aspect: Bool) -> UIImage {
        
        let originalRatio = self.size.width / self.size.height
        let newRatio = newSize.width / newSize.height
        
        var size: CGSize = CGSizeZero
        
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
        self.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
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
