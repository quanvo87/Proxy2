import PureLayout
import SkyFloatingLabelTextField
import SwiftyButton

class SignUpViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var facebookButton: CustomPressableButton!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var signUpButton: CustomPressableButton!

    private var loginManager: LoginManaging = LoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        facebookButton.configure(
            text: "Sign up with Facebbook",
            asFacebookButton: true
        )

        signUpButton.configure(text: "Sign up")
    }

    static func make(loginManager: LoginManaging = LoginManager()) -> SignUpViewController {
        guard let signUpViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.signUpViewController) as? SignUpViewController else {
            return SignUpViewController()
        }
        signUpViewController.loginManager = loginManager
        return signUpViewController
    }

    @IBAction func tapSignUpButton(_ sender: Any) {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorAlert(ProxyError.missingCredentials)
                return
        }
        loginManager.emailSignUp(email: email.lowercased(), password: password) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func tapFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }
}
