import SwiftVideoBackground

class LoginViewController: UIViewController {
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    private let videoBackground = VideoBackground()
    private var loginManager: LoginManaging = LoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        let videos = ["arabiangulf", "beachpalm", "hawaiiancoast"]
        videoBackground.play(view: view, videoName: videos[videos.count.random], videoType: "mp4", alpha: 0.1)

        facebookButton.configure()

        loginButton.configure()

        signUpButton.configure()

        emailTextField.clearButtonMode = .whileEditing

        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true
    }

    static func make(_ loginManager: LoginManaging = LoginManager()) -> LoginViewController? {
        guard let loginViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
            return nil
        }
        loginViewController.loginManager = loginManager
        return loginViewController
    }

    @IBAction func login(_ sender: AnyObject) {
        guard
            let email = emailTextField.text, email != "",
            let password = passwordTextField.text, password != "" else {
                showErrorAlert(ProxyError.missingCredentials)
                return
        }
        loginManager.emailLogin(email: email.lowercased(), password: password) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
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
}

private extension UIButton {
    func configure() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        setTitleColor(UIColor.white, for: UIControlState())
    }
}
