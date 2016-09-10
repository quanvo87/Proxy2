//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FacebookLogin

class LogInViewController: UIViewController {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillHide), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUp() {
        bottomConstraint.constant = view.frame.size.height / 3
        bottomConstraintConstant = bottomConstraint.constant
        emailTextField.clearButtonMode = .WhileEditing
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.secureTextEntry = true
    }
    
    @IBAction func logIn(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Missing Fields", message: "Please enter an email and password.")
                return
        }
        FIRAuth.auth()?.signInWithEmail(email, password: password) { (user, error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.localizedDescription)
                return
            }
            self.showHomeScreen()
        }
    }
    
    @IBAction func createNewAccount(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
                return
        }
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { (user, error) in
            if let error = error {
                self.showAlert("Error Creating Account", message: error.localizedDescription)
                return
            }
            let changeRequest = user!.profileChangeRequest()
            changeRequest.displayName = user!.email!
            changeRequest.commitChangesWithCompletion() { error in
                if let error = error {
                    self.showAlert("Error Setting Display Name For User", message: error.localizedDescription)
                    return
                }
                let user = user!.uid
                self.api.setDefaultIcons(forUser: user)
                self.showHomeScreen()
            }
        }
    }
    
    @IBAction func logInWithFacebook(sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([ .PublicProfile ], viewController: self) { (loginResult) in
            switch loginResult {
            case .Failed:
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again another time.")
                return
            case .Cancelled:
                return
            case .Success:
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    if let error = error {
                        self.showAlert("Error Logging In With Facebook", message: error.localizedDescription)
                        return
                    }
                    let user = user?.uid
                    self.ref.child("icons").queryOrderedByKey().queryEqualToValue(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        if !snapshot.hasChildren() {
                            self.api.setDefaultIcons(forUser: user!)
                        }
                    })
                    self.showHomeScreen()
                }
            }
        }
    }
    
    // MARK: - Keyboard
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
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
    
    // MARK: - Navigation
    func showHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}