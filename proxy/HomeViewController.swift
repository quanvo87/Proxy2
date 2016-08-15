//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FacebookLogin

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logout(sender: AnyObject) {
        
        let loginManager = LoginManager()
        loginManager.logOut()
        
        KCSUser.activeUser().logout()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signUpViewController  = storyboard.instantiateViewControllerWithIdentifier("Sign Up") as! SignUpViewController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = signUpViewController
    }
}
