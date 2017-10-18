import UIKit

// TODO: Add phone number sign up
class LoginViewController: UIViewController {
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    private let player = LoginVideoPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        player.play(view)
        setup(button: facebookButton)
        setup(button: loginButton)
        setup(button: signUpButton)
        emailTextField.clearButtonMode = .whileEditing
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true
    }

    @IBAction func login(_ sender: AnyObject) {
        LoginService.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.description)
                return
            }
            self.showHome()
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        LoginService.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Signing Up", message: error.description)
                return
            }
            self.showHome()
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        LoginService.facebookLogin(viewController: self) { (error) in
            if let error = error {
                self.showAlert("Error Logging In With Facebook", message: error.description)
                return
            }
            self.showHome()
        }
    }
}

private extension LoginViewController {
    func showHome() {
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate,
            let controller = storyboard?.instantiateViewController(withIdentifier: Identifier.tabBarController) as? UITabBarController else {
                return
        }
        delegate.window?.rootViewController = controller
    }

    func setup(button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.setTitleColor(UIColor.white, for: UIControlState())
    }
}
