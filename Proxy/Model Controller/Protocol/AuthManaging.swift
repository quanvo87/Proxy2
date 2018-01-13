import FirebaseAuth
import UIKit

protocol AuthManaging: class {
    func logIn(_ user: User)
    func logOut()
}

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
        let proxiesManager = ProxiesManager(user.uid)
        let presenceManager = PresenceManager()
        let unreadMessagesManager = UnreadMessagesManager(user.uid)
        presenceManager.load(unreadMessagesManager)
        unreadMessagesManager.load(presenceManager: presenceManager, proxiesManager: proxiesManager)
        window?.rootViewController = TabBarController(uid: user.uid,
                                                      displayName: displayName,
                                                      presenceManager: presenceManager,
                                                      proxiesManager: proxiesManager,
                                                      unreadMessagesManager: unreadMessagesManager)
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
