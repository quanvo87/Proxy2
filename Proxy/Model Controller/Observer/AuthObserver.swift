import FirebaseAuth

class AuthObserver {
    private var handle: AuthStateDidChangeListenerHandle?
    private lazy var auth = {
        Auth.auth()
    }()

    func load(_ manager: AuthManaging) {
        stopObserving()
        handle = auth.addStateDidChangeListener { [weak manager = manager] (_, user) in
            if let user = user {
                manager?.logIn(user)
            } else {
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
