import FacebookLogin
import FBSDKCoreKit
import FirebaseAuth
import WQNetworkActivityIndicator

protocol LoginManaging {
    typealias Callback = (Error?) -> Void
    func emailLogin(email: String, password: String, completion: @escaping Callback)
    func emailSignUp(email: String, password: String, completion: @escaping Callback)
    func facebookLogin(completion: @escaping Callback)
}

class LoginManager: LoginManaging {
    private lazy var facebookLoginManager = FacebookLogin.LoginManager()
    private weak var facebookButton: Button?
    private weak var loginButton: Button?
    private weak var signUpButton: Button?
    private weak var viewController: UIViewController?

    init(facebookButton: Button? = nil,
         loginButton: Button? = nil,
         signUpButton: Button? = nil,
         viewController: UIViewController? = nil) {
        self.facebookButton = facebookButton
        self.loginButton = loginButton
        self.signUpButton = signUpButton
        self.viewController = viewController
    }

    func emailLogin(email: String, password: String, completion: @escaping Callback) {
        loginButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.loginButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                self?.viewController?.showErrorBanner(error)
            } else {
                self?.viewController?.showSuccessBanner(
                    title: "Login successful",
                    subtitle: "Welcome back! 😊🎉"
                )
            }
        }
    }

    func emailSignUp(email: String, password: String, completion: @escaping Callback) {
        signUpButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.createUser(withEmail: email, password: password) { [weak self] _, error in
            self?.signUpButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                self?.viewController?.showErrorBanner(error)
            } else {
                self?.viewController?.showSuccessBanner(
                    title: "Sign up successful",
                    subtitle: "Welcome to Proxy!! 🤩🎉"
                )
            }
        }
    }

    func facebookLogin(completion: @escaping Callback) {
        facebookButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        facebookLoginManager.logIn(readPermissions: [.publicProfile]) { [weak self] result in
            self?.facebookButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            switch result {
            case .success:
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Shared.auth.signIn(with: credential) { _, error in
                    if let error = error {
                        self?.viewController?.showErrorBanner(error)
                    } else {
                        self?.viewController?.showSuccessBanner(
                            title: "Log in successful",
                            subtitle: "Welcome! 🤩🎉"
                        )
                    }
                }
            case .failed(let error):
                self?.viewController?.showErrorBanner(error)
            case .cancelled:
                return
            }
        }
    }
}
