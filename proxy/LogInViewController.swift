//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import VideoSplashKit
import FacebookLogin

class LogInViewController: VideoSplashViewController {
    
    let api = API.sharedInstance
    var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var createNewAccountButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoNames = ["arabiangulf", "beachpalm", "dragontailzipline", "hawaiiancoast"]
        let videoNamesCount = UInt32(videoNames.count)
        let random = Int(arc4random_uniform(videoNamesCount))
        let url = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource(videoNames[random], ofType: "mp4")!)
        self.alpha = 0.9
        self.alwaysRepeat = true
        self.contentURL = url
        self.fillMode = .ResizeAspectFill
        self.restartForeground = true
        self.sound = false
        self.videoFrame = view.frame
        
        emailTextField.clearButtonMode = .WhileEditing
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.secureTextEntry = true
        
        createNewAccountButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        createNewAccountButton.layer.borderColor = UIColor.whiteColor().CGColor
        createNewAccountButton.layer.borderWidth = 1
        createNewAccountButton.layer.cornerRadius = 5
        
        logInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        logInButton.layer.borderColor = UIColor.whiteColor().CGColor
        logInButton.layer.borderWidth = 1
        logInButton.layer.cornerRadius = 5
        
        facebookButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        facebookButton.layer.borderColor = UIColor.whiteColor().CGColor
        facebookButton.layer.borderWidth = 1
        facebookButton.layer.cornerRadius = 5
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
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
            guard error == nil else {
                self.showAlert("Error Logging In", message: error!.localizedDescription)
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
            guard error == nil else {
                self.showAlert("Error Creating Account", message: error!.localizedDescription)
                return
            }
            let changeRequest = user!.profileChangeRequest()
            changeRequest.displayName = user!.email!
            changeRequest.commitChangesWithCompletion() { error in
                guard error == nil else {
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
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again.")
                return
            case .Cancelled:
                return
            case .Success:
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    guard error == nil else {
                        self.showAlert("Error Logging In With Facebook", message: error!.localizedDescription)
                        return
                    }
                    let user = user?.uid
                    self.api.ref.child(Path.Icons).queryOrderedByKey().queryEqualToValue(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        if !snapshot.hasChildren() {
                            self.api.setDefaultIcons(forUser: user!)
                        }
                    })
                    self.showHomeScreen()
                }
            }
        }
    }
    
    func showHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}
