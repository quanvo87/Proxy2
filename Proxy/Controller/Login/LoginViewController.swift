import FontAwesome_swift
import PureLayout
import Segmentio
import SwiftyButton

class LoginViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var facebookButton: CustomPressableButton!
    @IBOutlet weak var facebookButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var segmentControl: Segmentio!

    private var currentViewController: UIViewController?

    private var loginManager: LoginManaging = LoginManager()

    private lazy var signUpViewController = makeSignUpViewController()

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

        segmentControl.setup(
            content: [
                SegmentioItem(title: "Sign Up", image: nil),
                SegmentioItem(title: "Log In", image: nil)
            ],
            style: .onlyLabel,
            options: segmentioOptions
        )

        segmentControl.valueDidChange = { [weak self] _, index in
            guard let _self = self else {
                return
            }
            _self.currentViewController?.view.removeFromSuperview()
            _self.currentViewController?.removeFromParentViewController()

            if index == 0 {
                _self.showViewController(_self.signUpViewController)
            }
        }

        segmentControl.selectedSegmentioIndex = 0

        configureFacebookButton()
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
    func showViewController(_ viewController: UIViewController) {
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        contentView.addSubview(viewController.view)
        currentViewController = viewController
    }

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
        icon.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(
                top: 10, left: 15, bottom: 10, right: 0
            ),
            excludingEdge: .right
        )

        let label = UILabel()
        label.text = "Log in with Facebook"
        label.textColor = .white
        facebookButton.contentView.addSubview(label)
        label.autoCenterInSuperview()
    }

    func makeSignUpViewController() -> SignUpViewController {
        guard let signUpViewController = UIStoryboard.main.instantiateViewController(withIdentifier: Identifier.signUpViewController) as? SignUpViewController else {
            return SignUpViewController()
        }
        signUpViewController.view.frame = contentView.bounds
        return signUpViewController
    }

    @IBAction func login(_ sender: AnyObject) {
//        guard
//            let email = emailTextField.text, email != "",
//            let password = passwordTextField.text, password != "" else {
//                showErrorAlert(ProxyError.missingCredentials)
//                return
//        }
//        loginManager.emailLogin(email: email.lowercased(), password: password) { [weak self] error in
//            if let error = error {
//                self?.showErrorAlert(error)
//            }
//        }
    }

    @objc func loginWithFacebook(_ sender: AnyObject) {
        loginManager.facebookLogin { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            }
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
//        guard
//            let email = emailTextField.text, email != "",
//            let password = passwordTextField.text, password != "" else {
//                showErrorAlert(ProxyError.missingCredentials)
//                return
//        }
//        loginManager.emailSignUp(email: email.lowercased(), password: password) { [weak self] error in
//            if let error = error {
//                self?.showErrorAlert(error)
//            }
//        }
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
