//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import AVFoundation
import FacebookLogin
import FirebaseAuth
import FirebaseDatabase

class LogInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var createNewAccountButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    let api = API.sharedInstance
    var player: AVPlayer?
    var bottomConstraintConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoNames = ["arabiangulf", "beachpalm", "dragontailzipline", "hawaiiancoast"]
        let random = Int(arc4random_uniform(UInt32(videoNames.count)))
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: videoNames[random], ofType: "mp4")!)
        player = AVPlayer(url: url)
        player?.actionAtItemEnd = .none
        player?.isMuted = true
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.frame
        playerLayer.opacity = 0.95
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.zPosition = -1
        view.layer.addSublayer(playerLayer)
        player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(LogInViewController.loopVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        emailTextField.clearButtonMode = .whileEditing
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true
        
        createNewAccountButton.layer.borderColor = UIColor.white.cgColor
        createNewAccountButton.layer.borderWidth = 1
        createNewAccountButton.layer.cornerRadius = 5
        createNewAccountButton.setTitleColor(UIColor.white, for: UIControlState())
        
        logInButton.layer.borderColor = UIColor.white.cgColor
        logInButton.layer.borderWidth = 1
        logInButton.layer.cornerRadius = 5
        logInButton.setTitleColor(UIColor.white, for: UIControlState())
        
        facebookButton.layer.borderColor = UIColor.white.cgColor
        facebookButton.layer.borderWidth = 1
        facebookButton.layer.cornerRadius = 5
        facebookButton.setTitleColor(UIColor.white, for: UIControlState())
    }
    
    func loopVideo() {
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    @IBAction func logIn(_ sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercased(),
            let password = passwordTextField.text, email != "" && password != "" else {
                showAlert("Missing Fields", message: "Please enter an email and password.")
                return
        }
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            guard error == nil else {
                self.showAlert("Error Logging In", message: error!.localizedDescription)
                return
            }
            self.showHomeScreen()
        }
    }
    
    @IBAction func createNewAccount(_ sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercased(),
            let password = passwordTextField.text, email != "" && password != "" else {
                showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
                return
        }
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            guard error == nil else {
                self.showAlert("Error Creating Account", message: error!.localizedDescription)
                return
            }
            let changeRequest = user!.profileChangeRequest()
            changeRequest.displayName = user!.email!
            changeRequest.commitChanges() { error in
                guard error == nil else {
                    return
                }
                let user = user!.uid
                self.api.setDefaultIcons(forUserId: user)
                self.showHomeScreen()
            }
        }
    }
    
    @IBAction func logInWithFacebook(_ sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile ], viewController: self) { (loginResult) in
            switch loginResult {
            case .failed:
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again.")
                return
            case .cancelled:
                return
            case .success:
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    guard error == nil else {
                        self.showAlert("Error Logging In With Facebook", message: error!.localizedDescription)
                        return
                    }
                    let user = user?.uid
                    self.api.ref.child(Path.Icons).queryOrderedByKey().queryEqual(toValue: user).observeSingleEvent(of: .value, with: { (snapshot) in
                        if !snapshot.hasChildren() {
                            self.api.setDefaultIcons(forUserId: user!)
                        }
                        self.showHomeScreen()
                    })
                }
            }
        }
    }
    
    func showHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}
