import FirebaseAuth
import UIKit

class AuthManager {
    private let authObserver = AuthObserver()
    private var loggedIn = false
    private weak var window: UIWindow?

    func load(_ window: UIWindow?) {
        self.window = window
        authObserver.load(self)
    }
}

extension AuthManager: AuthManaging {
    func logIn(_ user: User) {
        var displayName = user.displayName
        if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
            displayName = email
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges()
        }
        window?.rootViewController = TabBarController(displayName: displayName, uid: user.uid)
        loggedIn = true
    }

    func logOut() {
        guard
            loggedIn,
            let loginController = LoginViewController.make() else {
                return
        }
        window?.rootViewController = loginController
        loggedIn = false
    }
}
