//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

// TODO: - add phone number sign up, maybe remove email sign up?
class LogInViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!

    var videoPlayer: LogInVideoPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        videoPlayer = LogInVideoPlayer(view: view)

        emailTextField.clearButtonMode = .whileEditing

        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true

        signUpButton.layer.borderColor = UIColor.white.cgColor
        signUpButton.layer.borderWidth = 1
        signUpButton.layer.cornerRadius = 5
        signUpButton.setTitleColor(UIColor.white, for: UIControlState())

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
        LogInManager.emailLogIn(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        LogInManager.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Signing Up", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func logInWithFacebook(_ sender: AnyObject) {
        LogInManager.facebookLogIn(viewController: self) { (error) in
            if let error = error {
                self.showAlert("Error Logging In With Facebook", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    func goToHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}
