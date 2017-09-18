import FirebaseDatabase

class UnreadCountObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var delegate: UnreadCountObserving?
    private(set) var handle: DatabaseHandle?

    init(user: String = Shared.shared.uid, delegate: UnreadCountObserving) {
        ref = DB.makeReference(Child.userInfo, user, Child.unreadMessages)
        self.delegate = delegate
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self = self] (data) in
            self?.delegate?.setUnreadCount(Int(data.childrenCount))
        })
    }

    deinit {
        stopObserving()
    }
}

protocol UnreadCountObserving: class {
    func setUnreadCount(_ count: Int?)
}
