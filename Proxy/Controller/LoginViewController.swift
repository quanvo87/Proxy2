import UIKit
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

//        let videos = ["arabiangulf", "beachpalm", "dragontailzipline", "hawaiiancoast"]
        let videos = ["arabiangulf", "beachpalm", "hawaiiancoast"]
        let random = Int(arc4random_uniform(UInt32(videos.count)))

        videoBackground.play(view: view, videoName: videos[random], videoType: "mp4", alpha: 0.1)

        facebookButton.setupForLoginViewController()

        loginButton.setupForLoginViewController()

        signUpButton.setupForLoginViewController()

        emailTextField.clearButtonMode = .whileEditing

        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.isSecureTextEntry = true
    }

    @IBAction func login(_ sender: AnyObject) {
        LoginService.emailLogin(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            self.showAlert(title: "Error Logging In", message: error.description)
        }
    }

    @IBAction func loginWithFacebook(_ sender: AnyObject) {
        LoginService.facebookLogin { (error) in
            self.showAlert(title: "Error Logging In With Facebook", message: error.description)
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        LoginService.emailSignUp(email: emailTextField.text?.lowercased(), password: passwordTextField.text) { (error) in
            self.showAlert(title: "Error Signing Up", message: error.description)
        }
    }
}

extension LoginViewController: StoryboardMakable {
    static var identifier: String {
        return Identifier.loginViewController
    }
}

private extension UIButton {
    func setupForLoginViewController() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        setTitleColor(UIColor.white, for: UIControlState())
    }
}
