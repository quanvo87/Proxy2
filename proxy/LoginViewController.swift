// TODO: Add phone number sign up
class LoginViewController: UIViewController {
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    private var player = LoginVideoPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        player.play(self.view)

        emailTextField.clearButtonMode = .whileEditing
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true

        facebookButton.setupForLogin()
        loginButton.setupForLogin()
        signUpButton.setupForLogin()
    }

    @IBAction func login(_ sender: AnyObject) {
        ProxyLoginManager.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Logging In", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        ProxyLoginManager.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            if let error = error {
                self.showAlert("Error Signing Up", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        ProxyLoginManager.facebookLogin(viewController: self) { (error) in
            if let error = error {
                self.showAlert("Error Logging In With Facebook", message: error.description)
                return
            }
            self.goToHomeScreen()
        }
    }

    func goToHomeScreen() {
        if  let tabBarController = storyboard?.instantiateViewController(withIdentifier: Identifiers.TabBarController) as? UITabBarController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController = tabBarController
        }
    }
}

private extension UIButton {
    func setupForLogin() {
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 5
        self.setTitleColor(UIColor.white, for: UIControlState())
    }
}
