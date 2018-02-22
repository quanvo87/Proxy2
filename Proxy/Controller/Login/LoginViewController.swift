import SkyFloatingLabelTextField

// todo: change login to log in
class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var loginButton: Button!
    @IBOutlet weak var facebookButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(
        facebookButton: facebookButton,
        loginButton: loginButton,
        viewController: self
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Log in"

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

        loginButton.configure(centerLabelText: "Log in")

        facebookButton.configure(
            centerLabelText: "Log in with Facebook",
            asFacebookButton: true
        )
    }

    static func make(loginManager: LoginManaging? = nil) -> LoginViewController {
        guard let loginViewController = Shared.storyboard.instantiateViewController(
            withIdentifier: String(describing: LoginViewController.self)
            ) as? LoginViewController else {
                assertionFailure()
                return LoginViewController()
        }
        if let loginManager = loginManager {
            loginViewController.loginManager = loginManager
        }
        return loginViewController
    }
}

private extension LoginViewController {
    @IBAction func tappedFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { _ in }
    }

    @IBAction func tappedLoginButton(_ sender: Any) {
        login()
    }

    // todo
    @IBAction func tappedForgotPasswordButton(_ sender: Any) {
    }

    @objc func closeKeyboard() {
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
    }

    func login() {
        guard let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                StatusBar.showError(ProxyError.missingCredentials)
                return
        }
        loginManager.emailLogin(email: email.lowercased(), password: password) { _ in }
    }
}

extension LoginViewController: UITextFieldDelegate {
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
}
