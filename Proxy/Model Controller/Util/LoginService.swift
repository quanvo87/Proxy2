import FacebookLogin
import FBSDKCoreKit
import FirebaseAuth

// todo: extract to protocol
struct LoginService {
    static func emailLogin(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError(.blankCredentials))
                return
        }
        Auth.auth.signIn(withEmail: email, password: password) { (_, error) in
            completion(error)
        }
    }

    static func emailSignUp(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError(.blankCredentials))
                return
        }
        Auth.auth.createUser(withEmail: email, password: password) { (_, error) in
            completion(error)
        }
    }

    static func facebookLogin(completion: @escaping (Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile], viewController: UIViewController()) { (loginResult) in
            switch loginResult {
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
