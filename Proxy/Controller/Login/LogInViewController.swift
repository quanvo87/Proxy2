import SkyFloatingLabelTextField

class LogInViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var logInButton: Button!
    @IBOutlet weak var facebookButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(
        facebookButton: facebookButton,
        logInButton: logInButton
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

        logInButton.configure(centerLabelText: "Log in")

        facebookButton.configure(
            centerLabelText: "Log in with Facebook",
            asFacebookButton: true
        )
    }

    static func make(loginManager: LoginManaging? = nil) -> LogInViewController {
        guard let logInViewController = Constant.storyboard.instantiateViewController(
            withIdentifier: String(describing: LogInViewController.self)
            ) as? LogInViewController else {
                return LogInViewController()
        }
        if let loginManager = loginManager {
            logInViewController.loginManager = loginManager
        }
        return logInViewController
    }
}

private extension LogInViewController {
    @IBAction func didTapFacebookButton(_ sender: Any) {
        loginManager.facebookLogIn { _ in }
    }

    @IBAction func didTapLoginButton(_ sender: Any) {
        logIn()
    }

    @IBAction func didTapForgotPasswordButton(_ sender: Any) {
        let alert = UIAlertController(title: "Reset Password",
                                      message: "Enter your email to receive a password reset email.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.clearButtonMode = .whileEditing
            textField.keyboardType = .emailAddress
            textField.placeholder = "Email"
            textField.textContentType = .emailAddress
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak alert] _ in
            guard let email = alert?.textFields?[0].text?.trimmed else {
                return
            }
            self?.loginManager.sendPasswordReset(email) { _ in }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func closeKeyboard() {
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
    }

    func logIn() {
        guard let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                StatusBar.showErrorBanner(subtitle: ProxyError.missingCredentials.localizedDescription)
                return
        }
        loginManager.emailLogIn(email: email.lowercased(), password: password) { _ in }
    }
}

extension LogInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            passwordTextField.becomeFirstResponder()
        case 1:
            logIn()
        default:
            break
        }
        return true
    }
}
