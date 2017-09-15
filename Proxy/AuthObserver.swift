import FirebaseAuth

class AuthObserver {
    private let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?
    private weak var delegate: AuthObserving?

    init(_ delegate: AuthObserving) {
        self.delegate = delegate
    }

    func observe() {
        handle = auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                API.sharedInstance.uid = user.uid   // TODO: Remove
                self?.delegate?.logIn()
            } else {
                Shared.shared.uid = ""
                self?.delegate?.logOut()
            }
        }
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

protocol AuthObserving: class {
    func logIn()
    func logOut()
}
