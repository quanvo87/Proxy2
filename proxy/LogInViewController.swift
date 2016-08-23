//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FirebaseAuth
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let user = FIRAuth.auth()?.currentUser {
            self.signedIn(user)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func tapLogInButton(sender: AnyObject) {
        let email = emailTextField.text?.lowercaseString
        let password = passwordTextField.text
        if emailSyntaxChecker.isValidEmail(email!) && password != "" {
            FIRAuth.auth()?.signInWithEmail(email!, password: password!) { (user, error) in
                if error == nil {
                    self.logIn(user!)
                } else {
                    print("Error logging in: \(error)")
                }
            }
        } else {
            showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
        }
    }
    
    @IBAction func tapCreateNewAccountButton(sender: AnyObject) {
        let email = emailTextField.text?.lowercaseString
        let password = passwordTextField.text
        if emailSyntaxChecker.isValidEmail(email!) && password != "" {
            FIRAuth.auth()?.createUserWithEmail(email!, password: password!) { (user, error) in
                if error == nil {
                    self.setDisplayName(user!)
                } else {
                    print("Error creating account: \(error)")
                }
            }
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
                // login with facebook
            }
        }
    }
    
    func logIn(user: FIRUser) {
        //        MeasurementHelper.sendLoginEvent()
        API.sharedInstance.userDisplayName = user.displayName ?? user.email
        API.sharedInstance.userSignedIn = true
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.UserLoggedIn, object: nil, userInfo: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setDisplayName(user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = user.email!.componentsSeparatedByString("@")[0]
        changeRequest.commitChangesWithCompletion(){ (error) in
            if error == nil {
                self.logIn(FIRAuth.auth()!.currentUser!)
            } else {
                print("Error setting display name for user: \(error)")
            }
        }
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