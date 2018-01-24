import SwiftVideoBackground

class LoginViewController: UIViewController {
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    private let videoBackground = VideoBackground()

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

    @IBAction func login(_ sender: AnyObject) {
        LoginService.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { [weak self] (error) in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        LoginService.facebookLogin { [weak self] (error) in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        LoginService.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { [weak self] (error) in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }
}

extension LoginViewController: StoryboardMakable {
    static var identifier: String {
        return Identifier.loginViewController
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
