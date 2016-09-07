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
    
    let ref = FIRDatabase.database().reference()
    var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setUpTextField()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillHide), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUpUI() {
        bottomConstraint.constant = view.frame.size.height / 3
        bottomConstraintConstant = bottomConstraint.constant
    }
    
    @IBAction func tapLogInButton(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Missing Fields", message: "Please enter an email and password.")
                return
        }
        FIRAuth.auth()?.signInWithEmail(email, password: password) { user, error in
            if let error = error {
                self.showAlert("Error Logging In", message: error.localizedDescription)
                return
            }
            self.showHomeScreen()
        }
    }
    
    @IBAction func tapCreateNewAccountButton(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
                return
        }
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { user, error in
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
                let uid = user!.uid
                self.ref.child("users").child(uid).setValue(["username": user!.displayName!])
                
                // Give user access to the default icons
                let icons = [
                    "/users/\(uid)/icons/Astronaut Helmet-40": true,
                    "/users/\(uid)/icons/Badminton-40": true,
                    "/users/\(uid)/icons/Cat Profile-40": true,
                    "/users/\(uid)/icons/Einstein-40": true,
                    "/users/\(uid)/icons/Elephant-40": true,
                    "/users/\(uid)/icons/Gold Pot-40": true,
                    "/users/\(uid)/icons/Grill-40": true,
                    "/users/\(uid)/icons/Hornet Hive-40": true,
                    "/users/\(uid)/icons/Joke Suicide Squad-40": true,
                    "/users/\(uid)/icons/Overwatch-40": true,
                    "/users/\(uid)/icons/Pig With Lipstick-40": true,
                    "/users/\(uid)/icons/Rainbow-40": true,
                    "/users/\(uid)/icons/Rhinoceros-40": true,
                    "/users/\(uid)/icons/Rice Bowl-40": true,
                    "/users/\(uid)/icons/Super Mario-40": true,
                    "/users/\(uid)/icons/Targaryen House-40": true,
                    "/users/\(uid)/icons/Thanksgiving-40": true,
                    "/users/\(uid)/icons/US Airborne-40": true]
                self.ref.updateChildValues(icons)
                
                self.showHomeScreen()
            }
        }
    }
    
    @IBAction func tapFacebookButton(sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([ .PublicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .Failed:
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again another time.")
            case .Cancelled:
                break
            case .Success:
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { user, error in
                    if let error = error {
                        self.showAlert("Error Logging In With Facebook", message: error.localizedDescription)
                        return
                    }
                    let uid = user?.uid
                    self.ref.child("users").queryOrderedByKey().queryEqualToValue(uid).observeSingleEventOfType(.Value, withBlock: { snapshot in
                        if !snapshot.hasChildren() {
                            self.ref.child("users").child(uid!).setValue(["username": user!.displayName!, "unread": 0])
                        }
                    })
                    self.showHomeScreen()
                }
            }
        }
    }
    
    func showHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
    
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
    
    // MARK: - Text field
    
    func setUpTextField() {
        emailTextField.clearButtonMode = .WhileEditing
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.secureTextEntry = true
    }
}