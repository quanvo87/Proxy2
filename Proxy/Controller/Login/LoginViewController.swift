import SkyFloatingLabelTextField

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var facebookButton: Button!
    @IBOutlet weak var forgotPasswordButton: Button!
    @IBOutlet weak var loginButton: Button!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!

    private lazy var loginManager: LoginManaging = LoginManager(facebookButton)

    override func viewDidLoad() {
        super.viewDidLoad()

        facebookButton.setup(
            centerLabelText: "Log in with Facebook",
            asFacebookButton: true
        )

        let red = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
        forgotPasswordButton.setup(
            centerLabelText: "Forgot?",
            centerLabelFont: UIFont.systemFont(ofSize: 14),
            colors: .init(
                button: red,
                shadow: UIColor(red: 211/255, green: 56/255, blue: 40/255, alpha: 1)
            ),
            disabledColors: .init(
                button: red,
                shadow: .gray
            )
        )

        loginButton.setup(centerLabelText: "Log in")
    }

    static func make(loginManager: LoginManaging? = nil) -> LoginViewController {
        guard let loginViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
            return LoginViewController()
        }
        if let loginManager = loginManager {
            loginViewController.loginManager = loginManager
        }
        return loginViewController
    }

    @IBAction func tapFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    // todo
    @IBAction func tapForgotPasswordButton(_ sender: Any) {
    }

    @IBAction func tapLoginButton(_ sender: Any) {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorAlert(ProxyError.missingCredentials)
                return
        }
        loginButton.showLoadingIndicator()
        loginManager.emailLogin(email: email.lowercased(), password: password) { [weak self] error in
            self?.loginButton.hideActivityIndicator()
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }
}
