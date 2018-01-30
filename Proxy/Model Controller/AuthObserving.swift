import FirebaseAuth

protocol AuthObserving {
    func observe(_ authManager: AuthManaging)
}

class AuthObserver: AuthObserving {
    private var handle: AuthStateDidChangeListenerHandle?

    func observe(_ authManager: AuthManaging) {
        stopObserving()
        handle = Auth.auth.addStateDidChangeListener { [weak authManager] (_, user) in
            if let user = user {
                authManager?.logIn(user)
            } else {
                authManager?.logOut()
            }
        }
    }

    private func stopObserving() {
        if let handle = handle {
            Auth.auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopObserving()
    }
}
