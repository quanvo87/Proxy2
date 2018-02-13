import SkyFloatingLabelTextField

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var signUpButton: Button!
    @IBOutlet weak var facebookButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(
        facebookButton: facebookButton,
        signUpButton: signUpButton
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeKeyboardNavigationItem = UINavigationItem()
        closeKeyboardNavigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.cancel,
            target: self,
            action: #selector(closeKeyboard)
        )
        let closeKeyboardNavigationBar = UINavigationBar.makeCloseKeyboardNavigationBar(
            width: view.frame.width
        )
        closeKeyboardNavigationBar.pushItem(closeKeyboardNavigationItem, animated: true)

        emailTextField.delegate = self
        emailTextField.inputAccessoryView = closeKeyboardNavigationBar
        emailTextField.setupAsEmailTextField()
        emailTextField.tag = 0

        passwordTextField.delegate = self
        passwordTextField.inputAccessoryView = closeKeyboardNavigationBar
        passwordTextField.setupAsPasswordTextField()
        passwordTextField.tag = 1

        signUpButton.setup(centerLabelText: "Sign up")

        facebookButton.setup(
            centerLabelText: "Sign up with Facebook",
            asFacebookButton: true
        )
    }

    @objc func closeKeyboard() {
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
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

    private func signUp() {
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

    @IBAction func tapSignUpButton(_ sender: Any) {
        signUp()
    }

    @IBAction func tapFacebookButton(_ sender: Any) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }
}
