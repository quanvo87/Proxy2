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
    let ref = FIRDatabase.database().reference()
    var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var createNewAccountButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUp() {
        setUpVideoSplash()
        logInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        logInButton.layer.cornerRadius = 5
        logInButton.layer.borderWidth = 1
        logInButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        createNewAccountButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        createNewAccountButton.layer.cornerRadius = 5
        createNewAccountButton.layer.borderWidth = 1
        createNewAccountButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        facebookButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        facebookButton.layer.cornerRadius = 5
        facebookButton.layer.borderWidth = 1
        facebookButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        emailTextField.clearButtonMode = .WhileEditing
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.secureTextEntry = true
    }
    
    func setUpVideoSplash() {
        let videoNames = ["dragontailzipline", "arabiangulf", "beachpalm", "hawaiiancoast"]
        let videoNamesCount = UInt32(videoNames.count)
        let random = Int(arc4random_uniform(videoNamesCount))
        let url = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource(videoNames[random], ofType: "mp4")!)
        self.videoFrame = view.frame
        self.fillMode = .ResizeAspectFill
        self.alwaysRepeat = true
        self.sound = false
        self.alpha = 0.9
        self.restartForeground = true
        self.contentURL = url
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
                    self.ref.child(Path.Icons).queryOrderedByKey().queryEqualToValue(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
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
    
    // MARK: - Keyboard
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
}
