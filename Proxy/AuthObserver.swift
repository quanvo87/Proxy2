import FirebaseAuth
import UIKit

class AuthObserver {
    private let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?

    func observe(_ manager: AuthManaging) {
        stopObserving()
        handle = auth.addStateDidChangeListener { [weak manager = manager] (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                Shared.shared.userName = user.displayName ?? ""
                manager?.logIn()
            } else {
                Shared.shared.uid = ""
                Shared.shared.userName = ""
                manager?.logOut()
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
