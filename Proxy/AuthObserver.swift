import FirebaseAuth
import UIKit

class AuthObserver {
    private let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?
    private weak var delegate: AuthObserving?

    init(_ delegate: AuthObserving) {
        self.delegate = delegate
    }

    func observe() {
        stopObserving()
        handle = auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                Shared.shared.userName = user.displayName ?? ""
                self?.delegate?.logIn()
            } else {
                Shared.shared.uid = ""
                Shared.shared.userName = ""
                self?.delegate?.logOut()
            }
        }
    }

    private func stopObserving() {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopObserving()
    }
}

protocol AuthObserving: class {
    var storyboard: UIStoryboard? { get }
    func logIn()
}

extension AuthObserving {
    func logOut() {
        guard
            let loginVC = storyboard?.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        appDelegate.window?.rootViewController = loginVC
    }
}
