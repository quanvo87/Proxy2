import FirebaseAuth

class AuthObserver {
    private var handle: AuthStateDidChangeListenerHandle?

    func load(_ authManager: AuthManaging) {
        stopObserving()
        handle = Auth.auth.addStateDidChangeListener { [weak manager = authManager] (_, user) in
            if let user = user {
                manager?.logIn(user)
            } else {
                manager?.logOut()
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
