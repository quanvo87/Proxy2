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
        facebookButton.setupForLoginViewController()
        loginButton.setupForLoginViewController()
        signUpButton.setupForLoginViewController()
        emailTextField.clearButtonMode = .whileEditing
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true
    }

    @IBAction func login(_ sender: AnyObject) {
        LoginService.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            self.showAlert("Error Logging In", message: error.description)
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        LoginService.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            self.showAlert("Error Signing Up", message: error.description)
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        LoginService.facebookLogin { (error) in
            self.showAlert("Error Logging In With Facebook", message: error.description)
        }
    }
}

private extension UIButton {
    func setupForLoginViewController() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        setTitleColor(UIColor.white, for: UIControlState())
    }
}
