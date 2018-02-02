import FirebaseAuth

protocol AuthObserving {
    func observe(completion: @escaping (User?) -> Void)
}

class AuthObserver: AuthObserving {
    private var handle: AuthStateDidChangeListenerHandle?

    func observe(completion: @escaping (User?) -> Void) {
        stopObserving()
        handle = Auth.auth.addStateDidChangeListener { (_, user) in
            completion(user)
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
