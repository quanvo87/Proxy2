//
//  Extensions.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import Foundation

extension UIViewController {
    func showAlert(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .Alert)
        let alertButton: UIAlertAction = UIAlertAction(title: "Ok", style: .Default) { action in
        }
        alert.addAction(alertButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

//let loginManager = LoginManager()
//loginManager.logOut()
//
//KCSUser.activeUser().logout()
//
//let storyboard = UIStoryboard(name: "Main", bundle: nil)
//let signUpViewController  = storyboard.instantiateViewControllerWithIdentifier("Sign Up") as! SignUpViewController
//let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//appDelegate.window?.rootViewController = signUpViewController