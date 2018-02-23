import SkyFloatingLabelTextField

// todo: terms and priv pol
class SignUpViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var signUpButton: Button!
    @IBOutlet weak var facebookButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(
        facebookButton: facebookButton,
        signUpButton: signUpButton,
        viewController: self
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Sign up"

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

        signUpButton.configure(centerLabelText: "Sign up")

        facebookButton.configure(
            centerLabelText: "Sign up with Facebook",
            asFacebookButton: true
        )
    }

    static func make(loginManager: LoginManaging? = nil) -> SignUpViewController {
        guard let signUpViewController = Shared.storyboard.instantiateViewController(
            withIdentifier: String(describing: SignUpViewController.self)
            ) as? SignUpViewController else {
                assertionFailure()
                return SignUpViewController()
        }
        if let loginManager = loginManager {
            signUpViewController.loginManager = loginManager
        }
        return signUpViewController
    }
}

private extension SignUpViewController {
    @IBAction func tappedSignUpButton(_ sender: Any) {
        signUp()
    }

    @IBAction func tappedFacebookButton(_ sender: Any) {
        loginManager.facebookLogIn { _ in }
    }

    @objc func closeKeyboard() {
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
    }

    func signUp() {
        guard let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                StatusBar.showError(ProxyError.missingCredentials)
                return
        }
        loginManager.emailSignUp(email: email.lowercased(), password: password) { _ in }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            passwordTextField.becomeFirstResponder()
        case 1:
            signUp()
        default:
            break
        }
        return true
    }
}
