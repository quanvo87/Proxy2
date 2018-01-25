import FacebookLogin
import FBSDKCoreKit
import FirebaseAuth

protocol LoginManaging {
    typealias Callback = (Error?) -> Void
    func emailLogin(email: String, password: String, completion: @escaping Callback)
    func emailSignUp(email: String, password: String, completion: @escaping Callback)
    func facebookLogin(completion: @escaping Callback)
}

struct LoginManager: LoginManaging {
    let facebookLoginManager = FacebookLogin.LoginManager()

    func emailLogin(email: String, password: String, completion: @escaping Callback) {
        Auth.auth.signIn(withEmail: email, password: password) { (_, error) in
            completion(error)
        }
    }

    func emailSignUp(email: String, password: String, completion: @escaping Callback) {
        Auth.auth.createUser(withEmail: email, password: password) { (_, error) in
            completion(error)
        }
    }

    func facebookLogin(completion: @escaping Callback) {
        facebookLoginManager.logIn(readPermissions: [.publicProfile], viewController: UIViewController()) { (result) in
            switch result {
            case .success:
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth.signIn(with: credential) { (_, error) in
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
