import FontAwesome_swift
import PureLayout
import Segmentio
import SwiftyButton

class LoginViewController: UIViewController {
    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var facebookButton: CustomPressableButton!
    @IBOutlet weak var facebookButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    private var loginManager: LoginManaging = LoginManager()

//    private lazy var facebookButton = makeFacebookButton()
    private lazy var loginButton = makeLoginButton()
    private lazy var signUpButton = makeSignUpButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        let segmentioOptions = SegmentioOptions(
            backgroundColor: .clear,
            indicatorOptions: SegmentioIndicatorOptions(
                color: .blue
            ),
            horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(
                type: .bottom,
                color: .lightGray
            ),
            verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(
                color: .clear
            ),
            segmentStates: SegmentioStates(
                defaultState: segmentioState,
                selectedState: segmentioState,
                highlightedState: segmentioState
            )
        )

        segmentio.setup(
            content: [
                SegmentioItem(title: "Sign Up", image: nil),
                SegmentioItem(title: "Log In", image: nil)
            ],
            style: .onlyLabel,
            options: segmentioOptions
        )

        segmentio.selectedSegmentioIndex = 0

        configureFacebookButton()

//        view.addSubview(facebookButton)
//        view.addSubview(loginButton)
//        view.addSubview(signUpButton)
//
//        let buttons = [loginButton, signUpButton]
//        (buttons as NSArray).autoSetViewsDimension(.height, toSize: 45)
//        (buttons as NSArray).autoMatchViewsDimension(.width)
//
//        for button in buttons {
//            button.autoPinEdge(.bottom, to: .top, of: facebookButton, withOffset: -5)
//        }
//
//        loginButton.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
//        loginButton.autoPinEdge(.left, to: .right, of: signUpButton, withOffset: 5)
//
//        signUpButton.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
//
//        facebookButton.autoCenterInSuperview()
//        facebookButton.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
//        facebookButton.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
//        facebookButton.autoSetDimension(.height, toSize: 45)
    }

    static func make(_ loginManager: LoginManaging = LoginManager()) -> LoginViewController? {
        guard let loginViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
            return nil
        }
        loginViewController.loginManager = loginManager
        return loginViewController
    }
}

private extension LoginViewController {
    var segmentioState: SegmentioState {
        return SegmentioState(
            backgroundColor: .clear,
            titleFont: UIFont.systemFont(ofSize: UIFont.systemFontSize),
            titleTextColor: .lightGray
        )
    }

    func configureFacebookButton() {
        facebookButton.colors = .init(button: .facebookBlue, shadow: .facebookDarkBlue)
        facebookButton.addTarget(self, action: #selector(loginWithFacebook), for: .touchUpInside)

        let icon = UILabel()
        icon.font = UIFont.fontAwesome(ofSize: 20)
        icon.text = String.fontAwesomeIcon(name: .facebook)
        icon.textColor = .white
        facebookButton.contentView.addSubview(icon)
        icon.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 0),
                                          excludingEdge: .right)

        let label = UILabel()
        label.text = "Log in with Facebook"
        label.textColor = .white
        facebookButton.contentView.addSubview(label)
        label.autoCenterInSuperview()
    }

    func makeLoginButton() -> CustomPressableButton {
        let loginButton = CustomPressableButton.make()
        loginButton.colors = .init(button: .customRed, shadow: .darkRed)

        let label = UILabel()
        label.text = "Log In"
        label.textColor = .white
        loginButton.contentView.addSubview(label)
        label.autoCenterInSuperview()

        return loginButton
    }

    func makeSignUpButton() -> CustomPressableButton {
        let signUpButton = CustomPressableButton.make()

        let label = UILabel()
        label.text = "Sign Up"
        label.textColor = .white
        signUpButton.contentView.addSubview(label)
        label.autoCenterInSuperview()

        return signUpButton
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

    @objc func loginWithFacebook(_ sender: AnyObject) {
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

private extension CustomPressableButton {
    static func make() -> CustomPressableButton {
        let button = CustomPressableButton()
        button.cornerRadius = 5
        button.shadowHeight = 5
        return button
    }
}

private extension UIColor {
    static var customRed: UIColor {
        return UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
    }

    static var customYellow: UIColor {
        return UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1)
    }

    static var darkRed: UIColor {
        return UIColor(red: 211/255, green: 56/255, blue: 40/255, alpha: 1)
    }

    static var darkYellow: UIColor {
        return UIColor(red: 221/255, green: 176/255, blue: 0/255, alpha: 1)
    }

    static var facebookBlue: UIColor {
        return UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1)
    }

    static var facebookDarkBlue: UIColor {
        return UIColor(red: 39/255, green: 69/255, blue: 132/255, alpha: 1)
    }
}
