//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FacebookLogin

class LogInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var bottomConstraintConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordTextField.delegate = self
        passwordTextField.secureTextEntry = true
        
        bottomConstraint.constant = view.frame.size.height / 3
        bottomConstraintConstant = bottomConstraint.constant
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func tapLogInButton(sender: AnyObject) {
        self.passwordTextField.resignFirstResponder()
        logIn()
    }
    
    func logIn() {
        let email = emailTextField.text
        let password = passwordTextField.text
        if isValidEmail(email!) && password != "" {
            KCSUser.loginWithUsername(
                email,
                password: password,
                withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, result: KCSUserActionResult) -> Void in
                    if errorOrNil == nil {
                        self.presentHomeScreen()
                    } else {
                        self.showAlert("That email/password was incorrect. Please try again.")
                    }
                }
            )
        } else {
            showAlert("Please enter a valid email and password.")
        }
    }
    
    func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    @IBAction func tapFacebookLogInButton(sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([ .PublicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .Failed(let error):
                print(error)
            case .Cancelled:
                print("User cancelled login.")
            case .Success:
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                KCSUser.loginWithSocialIdentity(
                    KCSUserSocialIdentifyProvider.SocialIDFacebook,
                    accessDictionary: [ KCSUserAccessTokenKey : accessToken ],
                    withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, result: KCSUserActionResult) -> Void in
                        if errorOrNil == nil {
                            self.presentHomeScreen()
                        } else {
                            print("Login to Facebook failed: \(errorOrNil)")
                        }
                    }
                )
            }
        }
    }
    
    func presentHomeScreen() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapCreateAccountButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Keyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.passwordTextField.resignFirstResponder()
        logIn()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        bottomConstraint.constant = bottomConstraintConstant
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
}