import FirebaseAuth

protocol AuthObserving {
    init(_ authManager: AuthManaging)
    func observe()
}

class AuthObserver: AuthObserving {
    private let authManager: AuthManaging
    private var handle: AuthStateDidChangeListenerHandle?

    required init(_ authManager: AuthManaging) {
        self.authManager = authManager
    }

    func observe() {
        stopObserving()
        handle = Auth.auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                self?.authManager.logIn(user)
            } else {
                self?.authManager.logOut()
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
