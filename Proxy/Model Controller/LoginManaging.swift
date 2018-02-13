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

    init(facebookButton: Button? = nil,
         loginButton: Button? = nil,
         signUpButton: Button? = nil) {
        self.facebookButton = facebookButton
        self.loginButton = loginButton
        self.signUpButton = signUpButton
    }

    func emailLogin(email: String, password: String, completion: @escaping Callback) {
        loginButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Auth.auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.loginButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            completion(error)
        }
    }

    func emailSignUp(email: String, password: String, completion: @escaping Callback) {
        signUpButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Auth.auth.createUser(withEmail: email, password: password) { [weak self] _, error in
            self?.signUpButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            completion(error)
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
                Auth.auth.signIn(with: credential) { _, error in
                    completion(error)
                }
            case .failed(let error):
                completion(error)
            case .cancelled:
                return
            }
        }
    }
}
