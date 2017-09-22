import FirebaseAuth
import UIKit

class AuthObserver {
    private let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?
    private weak var manager: AuthManaging?

    init(_ manager: AuthManaging) {
        self.manager = manager
        observe()
    }

    func observe() {
        stopObserving()
        handle = auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                Shared.shared.userName = user.displayName ?? ""
                self?.manager?.logIn()
            } else {
                Shared.shared.uid = ""
                Shared.shared.userName = ""
                self?.manager?.logOut()
            }
        }
    }

    func stopObserving() {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopObserving()
    }
}

protocol AuthManaging: class {
    func logIn()
}

extension AuthManaging {
    func logOut() {
        guard
            let controller = self as? UIViewController,
            let loginVC = controller.storyboard?.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        appDelegate.window?.rootViewController = loginVC
    }
}
