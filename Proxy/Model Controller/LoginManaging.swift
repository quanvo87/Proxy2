import FacebookLogin
import FBSDKCoreKit
import FirebaseAuth
import WQNetworkActivityIndicator

protocol LoginManaging {
    typealias Callback = (Error?) -> Void
    func emailLogin(email: String, password: String, completion: @escaping Callback)
    func emailSignUp(email: String, password: String, completion: @escaping Callback)
    func facebookLogIn(completion: @escaping Callback)
    func sendPasswordReset(_ email: String, completion: @escaping Callback)
}

class LoginManager: LoginManaging {
    private lazy var facebookLoginManager = FacebookLogin.LoginManager()
    private weak var facebookButton: Button?
    private weak var logInButton: Button?
    private weak var signUpButton: Button?
    private weak var viewController: UIViewController?

    init(facebookButton: Button? = nil,
         logInButton: Button? = nil,
         signUpButton: Button? = nil,
         viewController: UIViewController? = nil) {
        self.facebookButton = facebookButton
        self.logInButton = logInButton
        self.signUpButton = signUpButton
        self.viewController = viewController
    }

    func emailLogin(email: String, password: String, completion: @escaping Callback) {
        logInButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.logInButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                StatusBar.showSuccessStatusBarBanner("Log in successful. Welcome! 🎉")
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
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                StatusBar.showSuccessStatusBarBanner("Sign up successful. Welcome! 🎉")
            }
        }
    }

    func facebookLogIn(completion: @escaping Callback) {
        facebookButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        facebookLoginManager.logIn(readPermissions: [.publicProfile]) { [weak self] result in
            self?.facebookButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            switch result {
            case .success:
                let credential = FacebookAuthProvider.credential(
                    withAccessToken: FBSDKAccessToken.current().tokenString
                )
                Shared.auth.signIn(with: credential) { _, error in
                    if let error = error {
                        StatusBar.showErrorBanner(subtitle: error.localizedDescription)
                    } else {
                        StatusBar.showSuccessStatusBarBanner("Log in successful. Welcome! 🎉")
                    }
                }
            case .failed(let error):
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            case .cancelled:
                return
            }
        }
    }

    func sendPasswordReset(_ email: String, completion: @escaping Callback) {
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.sendPasswordReset(withEmail: email) { (error) in
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                StatusBar.showSuccessBanner(
                    title: "Password reset email sent!",
                    subtitle: "Check your email to reset your password 📧."
                )
            }
        }
    }
}
