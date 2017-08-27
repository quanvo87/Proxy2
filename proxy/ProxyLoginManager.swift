import FirebaseAuth
import FacebookLogin

struct ProxyLoginManager {}

extension ProxyLoginManager {
    static func emailLogin(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError(.blankCredentials))
                return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            changeDisplayName(user: user, error: error, email: email, completion: completion)
        }
    }

    static func emailSignUp(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError(.blankCredentials))
                return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            changeDisplayName(user: user, error: error, email: email, completion: completion)
        }
    }

    private static func changeDisplayName(user: User?, error: Error?, email: String, completion: (Error?) -> Void) {
        if let user = user, user.displayName != email {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges()
        }
        finishLogin(user: user, error: error, completion: completion)
    }
}

extension ProxyLoginManager {
    static func facebookLogin(viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile], viewController: viewController) { (loginResult) in
            switch loginResult {
            case .success:
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth().signIn(with: credential) { (user, error) in
                    finishLogin(user: user, error: error, completion: completion)
                }
            case .failed(let error):
                completion(error)
            case .cancelled:
                return
            }
        }
    }
}

private extension ProxyLoginManager {
    static func finishLogin(user: User?, error: Error?, completion: (Error?) -> Void) {
        if let user = user {
            Shared.shared.uid = user.uid
        }
        completion(error)
    }
}
