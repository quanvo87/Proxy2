import SkyFloatingLabelTextField
import SwiftyButton

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var facebookButton: CustomPressableButton!
    @IBOutlet weak var forgotPasswordButton: CustomPressableButton!
    @IBOutlet weak var loginButton: CustomPressableButton!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!

    private var loginManager: LoginManaging = LoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        facebookButton.configure(
            text: "Log in with Facebook",
            asFacebookButton: true
        )

        forgotPasswordButton.configure(
            text: "Forgot?",
            colors: .init(
                button: UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1),
                shadow: UIColor(red: 211/255, green: 56/255, blue: 40/255, alpha: 1)
            ),
            fontSize: 14
        )

        loginButton.configure(text: "Log in")
    }

    static func make(loginManager: LoginManaging = LoginManager()) -> LoginViewController {
        guard let loginViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
            return LoginViewController()
        }
        loginViewController.loginManager = loginManager
        return loginViewController
    }

    @IBAction func tapFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func tapForgotPasswordButton(_ sender: Any) {
    }

    @IBAction func tapLoginButton(_ sender: Any) {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorAlert(ProxyError.missingCredentials)
                return
        }
        loginManager.emailLogin(email: email.lowercased(), password: password) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }
}
