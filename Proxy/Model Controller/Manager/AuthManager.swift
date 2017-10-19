import FirebaseAuth
import UIKit

class AuthManager {
    private let observer = AuthObserver()
    private var loggedIn = false
    private weak var delegate: AppDelegate?

    func load(_ delegate: AppDelegate) {
        self.delegate = delegate
        observer.load(self)
    }
}

extension AuthManager: AuthManaging {
    func logIn(_ user: User) {
        if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges { (error) in
                guard error == nil else { return }
                user.reload { (error) in
                    guard error == nil, let user = Auth.auth.currentUser else { return }
                    self.delegate?.window.rootViewController = TabBarController(displayName: user.displayName ?? "", uid: user.uid)
                    self.loggedIn = true
                    return
                }
            }
        }
        delegate?.window.rootViewController = TabBarController(displayName: user.displayName ?? "", uid: user.uid)
        loggedIn = true
    }

    func logOut() {
        guard loggedIn else { return }

        // delete
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginController = storyboard.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else { return }

        delegate?.window.rootViewController = loginController
        loggedIn = false
    }
}
