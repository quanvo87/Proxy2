//
//  LoginViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

// TODO: - add phone number sign up, maybe remove email sign up?
class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!

    lazy var videoPlayer = LoginVideoPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        videoPlayer.play(self.view)

        emailTextField.clearButtonMode = .whileEditing
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true

        signUpButton.setupForLogin()
        loginButton.setupForLogin()
        facebookButton.setupForLogin()
    }

    @IBAction func login(_ sender: AnyObject) {
        Login.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        Login.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Signing Up", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        Login.facebookLogin(viewController: self) { (error) in
            if let error = error {
                self.showAlert("Error Logging In With Facebook", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    func goToHomeScreen() {
        if  let tabBarController = storyboard?.instantiateViewController(withIdentifier: Identifiers.TabBarController) as? UITabBarController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            appDelegate.window?.rootViewController = tabBarController
        }
    }
}

private extension UIButton {
    func setupForLogin() {
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 5
        self.setTitleColor(UIColor.white, for: UIControlState())
    }
}
