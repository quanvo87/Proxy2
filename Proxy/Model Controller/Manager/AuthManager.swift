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
            changeRequest.commitChanges()
            logIn(displayName: email, uid: user.uid)
        }
        logIn(displayName: user.displayName ?? "", uid: user.uid)
    }

    private func logIn(displayName: String, uid: String) {
        delegate?.window.rootViewController = TabBarController(displayName: displayName, uid: uid)
        loggedIn = true
        Shared.shared.queue.async {
            DBProxy.fixConvoCounts(uid: uid) { _ in }
        }
    }

    func logOut() {
        guard loggedIn else { return }

        // delete
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginController = storyboard.instantiateViewController(withIdentifier: Name.loginViewController) as? LoginViewController else { return }

        delegate?.window.rootViewController = loginController
        loggedIn = false
    }
}
