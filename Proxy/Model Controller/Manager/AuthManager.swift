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
        if user.displayName != user.email {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = user.email
            changeRequest.commitChanges()
        }
        delegate?.window.rootViewController = TabBarController(user)
        loggedIn = true
    }

    func logOut() {
        guard loggedIn else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginController = storyboard.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else { return }
        delegate?.window.rootViewController = loginController
        loggedIn = false
    }
}
