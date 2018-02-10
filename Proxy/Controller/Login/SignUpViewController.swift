import PureLayout
import SkyFloatingLabelTextField
import SwiftyButton

// todo: track last first responder
class SignUpViewController: UIViewController {
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var signUpButton: CustomPressableButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSignUpButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        emailTextField.becomeFirstResponder()
    }
}

private extension SignUpViewController {
    func configureSignUpButton() {
        let label = UILabel()
        label.text = "Sign up!"
        label.textColor = .white
        signUpButton.contentView.addSubview(label)
        label.autoCenterInSuperview()
    }
}
