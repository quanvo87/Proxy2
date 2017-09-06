import FirebaseAuth

class AuthObserver {
    private var auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {}

    func observe(_ delegate: AuthObserverDelegate) {
        handle = auth.addStateDidChangeListener { [weak delegate = delegate] (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                API.sharedInstance.uid = user.uid   // TODO: Remove
                delegate?.logIn()
            } else {
                Shared.shared.uid = ""
                delegate?.logOut()
            }
        }
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

protocol AuthObserverDelegate: class {
    func logIn()
    func logOut()
}
