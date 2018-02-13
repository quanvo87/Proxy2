import SkyFloatingLabelTextField

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var facebookButton: Button!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var signUpButton: Button!

    private lazy var loginManager: LoginManaging = LoginManager(facebookButton)

    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.setupAsEmailTextField()
        emailTextField.delegate = self
        emailTextField.tag = 0

        passwordTextField.setupAsPasswordTextField()
        passwordTextField.delegate = self
        passwordTextField.tag = 1

        signUpButton.setup(centerLabelText: "Sign up")

        facebookButton.setup(
            centerLabelText: "Sign up with Facebook",
            asFacebookButton: true
        )
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
        signUpButton.showLoadingIndicator()
        loginManager.emailSignUp(email: email.lowercased(), password: password) { [weak self] error in
            self?.signUpButton.hideActivityIndicator()
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
