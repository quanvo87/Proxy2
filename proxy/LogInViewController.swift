//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

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
    var videoPlayer: LogInVideoPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        videoPlayer = LogInVideoPlayer(view: view)

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

    @IBAction func logIn(_ sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercased(), email != "",
            let password = passwordTextField.text, password != "" else {
                showAlert("Missing Fields", message: "Please enter a valid email and password.")
                return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.localizedDescription)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func createNewAccount(_ sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercased(), email != "",
            let password = passwordTextField.text, password != "" else {
                showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
                return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                self.showAlert("Error Creating Account", message: error.localizedDescription)
                return
            }
            guard
                let user = user,
                let email = user.email else {
                    self.showAlert("Error Creating User", message: "Unable to create user. Please try again.")
                    return
            }
            // check this on every log in
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges() { _ in
                self.api.setDefaultIcons(forUserId: user.uid)
                self.goToHomeScreen()
            }
        }
    }

    @IBAction func logInWithFacebook(_ sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile], viewController: self) { (loginResult) in
            switch loginResult {
            case .success:
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth().signIn(with: credential) { (user, error) in
                    if let error = error {
                        self.showAlert("Error Logging In With Facebook", message: error.localizedDescription)
                        return
                    }
                    // unwrap
                    let userId = user?.uid
                    self.api.ref.child(Path.Icons).queryOrderedByKey().queryEqual(toValue: userId).observeSingleEvent(of: .value, with: { (snapshot) in
                        if !snapshot.hasChildren() {
                            self.api.setDefaultIcons(forUserId: userId!)
                        }
                        self.goToHomeScreen()
                    })
                }
            case .failed:
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again.")
            default:
                return
            }
        }
    }

    func goToHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}
