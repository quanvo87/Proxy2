import FirebaseAuth

class AuthObserver {
    private var handle = Auth.auth()

    init() {}

    func observe(_ delegate: AuthObserverDelegate) {
        handle.addStateDidChangeListener { (_, user) in
            if let user = user {
                Shared.shared.uid = user.uid
                API.sharedInstance.uid = user.uid   // TODO: Remove
                delegate.logIn()
            } else {
                Shared.shared.uid = ""
                delegate.logOut()
            }
        }
    }

    deinit {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}

protocol AuthObserverDelegate {
    func logIn()
    func logOut()
}
