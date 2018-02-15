import SkyFloatingLabelTextField

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var forgotPasswordButton: Button!
    @IBOutlet weak var loginButton: Button!
    @IBOutlet weak var facebookButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(
        facebookButton: facebookButton,
        loginButton: loginButton,
        viewController: self
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeKeyboardNavigationBar = UINavigationBar(
            target: self,
            action: #selector(closeKeyboard),
            width: view.frame.width
        )

        emailTextField.delegate = self
        emailTextField.inputAccessoryView = closeKeyboardNavigationBar
        emailTextField.setupAsEmailTextField()
        emailTextField.tag = 0

        passwordTextField.delegate = self
        passwordTextField.inputAccessoryView = closeKeyboardNavigationBar
        passwordTextField.setupAsPasswordTextField()
        passwordTextField.tag = 1

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

        facebookButton.setup(
            centerLabelText: "Continue with Facebook",
            asFacebookButton: true
        )
    }

    @objc func closeKeyboard() {
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
    }

    static func make(loginManager: LoginManaging? = nil) -> LoginViewController {
        guard let loginViewController = UI.storyboard.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
            return LoginViewController()
        }
        if let loginManager = loginManager {
            loginViewController.loginManager = loginManager
        }
        return loginViewController
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            passwordTextField.becomeFirstResponder()
        case 1:
            login()
        default:
            break
        }
        return true
    }

    private func login() {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorBanner(ProxyError.missingCredentials)
                return
        }
        loginManager.emailLogin(email: email.lowercased(), password: password) { _ in }
    }

    // todo
    @IBAction func tapForgotPasswordButton(_ sender: Any) {
    }

    @IBAction func tapLoginButton(_ sender: Any) {
        login()
    }

    @IBAction func tapFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { _ in }
    }
}
