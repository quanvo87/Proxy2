import FirebaseAuth
import UIKit

class AuthManager {
    private var handle: AuthStateDidChangeListenerHandle?
    private var loggedIn = false
    private weak var window: UIWindow?

    init(_ window: UIWindow?) {
        self.window = window
    }

    func observe() {
        stopObserving()
        handle = Auth.auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                var displayName = user.displayName
                if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
                    displayName = email
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = email
                    changeRequest.commitChanges()
                }
                self?.window?.rootViewController = TabBarController(uid: user.uid,
                                                                    displayName: displayName)
                self?.loggedIn = true
            } else {
                guard
                    self?.loggedIn ?? false,
                    let loginController = LoginViewController.make() else {
                        return
                }
                self?.window?.rootViewController = loginController
                self?.loggedIn = false
            }
        }
    }

    func stopObserving() {
        if let handle = handle {
            Auth.auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopObserving()
    }
}
