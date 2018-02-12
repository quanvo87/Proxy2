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
    private let facebookLoginManager = FacebookLogin.LoginManager()
    private weak var facebookButton: Button?

    init(_ facebookButton: Button) {
        self.facebookButton = facebookButton
    }

    func emailLogin(email: String, password: String, completion: @escaping Callback) {
        WQNetworkActivityIndicator.shared.show()
        Auth.auth.signIn(withEmail: email, password: password) { _, error in
            WQNetworkActivityIndicator.shared.hide()
            completion(error)
        }
    }

    func emailSignUp(email: String, password: String, completion: @escaping Callback) {
        WQNetworkActivityIndicator.shared.show()
        Auth.auth.createUser(withEmail: email, password: password) { _, error in
            WQNetworkActivityIndicator.shared.hide()
            completion(error)
        }
    }

    func facebookLogin(completion: @escaping Callback) {
        WQNetworkActivityIndicator.shared.show()
        facebookButton?.showLoadingIndicator()
        facebookLoginManager.logIn(readPermissions: [.publicProfile]) { [weak self] result in
            WQNetworkActivityIndicator.shared.hide()
            self?.facebookButton?.hideActivityIndicator()
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
