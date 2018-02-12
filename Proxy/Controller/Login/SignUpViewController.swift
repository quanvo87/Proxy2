import SkyFloatingLabelTextField

class SignUpViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var facebookButton: Button!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var signUpButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(facebookButton)

    override func viewDidLoad() {
        super.viewDidLoad()

        facebookButton.setup(
            centerLabelText: "Sign up with Facebook",
            asFacebookButton: true
        )

        signUpButton.setup(centerLabelText: "Sign up")
    }

    static func make(loginManager: LoginManaging? = nil) -> SignUpViewController {
        guard let signUpViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.signUpViewController) as? SignUpViewController else {
            return SignUpViewController()
        }
        if let loginManager = loginManager {
            signUpViewController.loginManager = loginManager
        }
        return signUpViewController
    }

    @IBAction func tapSignUpButton(_ sender: Any) {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorAlert(ProxyError.missingCredentials)
                return
        }
        signUpButton.showLoadingIndicator()
        loginManager.emailSignUp(email: email.lowercased(), password: password) { [weak self] error in
            self?.signUpButton.hideActivityIndicator()
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
