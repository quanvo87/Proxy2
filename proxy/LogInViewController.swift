//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FacebookLogin

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    private let ref = FIRDatabase.database().reference()
    private let emailSyntaxChecker = EmailSyntaxChecker()
    private var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUpUI() {
        emailTextField.clearButtonMode = .WhileEditing
        
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.delegate = self
        passwordTextField.secureTextEntry = true
        
        bottomConstraint.constant = view.frame.size.height / 3
        bottomConstraintConstant = bottomConstraint.constant
    }
    
    @IBAction func tapLogInButton(sender: AnyObject) {
        let email = emailTextField.text?.lowercaseString
        let password = passwordTextField.text
        if emailSyntaxChecker.isValidEmail(email!) && password != "" {
            FIRAuth.auth()?.signInWithEmail(email!, password: password!) { (user, error) in
                if error == nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    self.showAlert("Error Logging In", message: error!.localizedDescription)
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
                    let changeRequest = user!.profileChangeRequest()
                    changeRequest.displayName = user!.email!.componentsSeparatedByString("@")[0]
                    changeRequest.commitChangesWithCompletion(){ (error) in
                        if error == nil {
                            self.ref.child("users").child(user!.uid).setValue(["username": user!.displayName!])
                            self.dismissViewControllerAnimated(true, completion: nil)
                        } else {
                            self.showAlert("Error Setting Display Name For User", message: error!.localizedDescription)
                        }
                    }
                } else {
                    self.showAlert("Error Creating Account", message: error!.localizedDescription)
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
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    if let error = error {
                        self.showAlert("Error Logging In With Facebook", message: error.localizedDescription)
                    } else {
                        if (FIRAuth.auth()?.currentUser) != nil {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                }
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