import FirebaseAuth
import UIKit

class AuthManager {
    private let authObserver = AuthObserver()
    private let presenceManager = PresenceManager()
    private var loggedIn = false
    private weak var window: UIWindow?

    func load(_ window: UIWindow?) {
        self.window = window
        authObserver.load(self)
    }
}

extension AuthManager: AuthManaging {
    func logIn(_ user: User) {
        if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges()
        }
        presenceManager.load(user.uid)
        window?.rootViewController = TabBarController(displayName: user.displayName ?? user.email ?? "", uid: user.uid)
        loggedIn = true
        DispatchQueue.queue.async {
            DBProxy.fixConvoCounts(uid: user.uid) { _ in }
        }
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
