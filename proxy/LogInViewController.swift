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
    private var bottomConstraintConstant: CGFloat = 0.0
    private let emailSyntaxChecker = EmailSyntaxChecker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.clearButtonMode = .WhileEditing
        
        passwordTextField.clearButtonMode = .WhileEditing
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
        let email = emailTextField.text?.lowercaseString
        let password = passwordTextField.text
        if emailSyntaxChecker.isValidEmail(email!) && password != "" {
            KCSUser.loginWithUsername(
                email,
                password: password,
                withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, result: KCSUserActionResult) -> Void in
                    if errorOrNil == nil {
                        self.presentHomeScreen()
                    } else {
                        self.showAlert("Incorrect Email/Password", message: "That email/password was incorrect. Please try again.")
                    }
                }
            )
        } else {
            showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
        }
    }
    
    @IBAction func tapCreateNewAccountButton(sender: AnyObject) {
        let email = emailTextField.text?.lowercaseString
        let password = passwordTextField.text
        if emailSyntaxChecker.isValidEmail(email!) && password != "" {
            KCSUser.userWithUsername(
                email,
                password: password,
                fieldsAndValues: nil,
                withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, result: KCSUserActionResult) -> Void in
                    if errorOrNil == nil {
                        self.presentHomeScreen()
                    } else {
                        self.showAlert("Email Taken", message: "There is already an account with that email.")
                    }
                }
            )
        } else {
            showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
        }
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
    
    // MARK: - Keyboard
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