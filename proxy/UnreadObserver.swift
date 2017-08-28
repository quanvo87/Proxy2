import FirebaseDatabase

class UnreadObserver {
    private weak var ref: DatabaseReference?

    init() {}

    func observe(_ delegate: UnreadObserverDelegate) {
        ref = DB.makeReference(Child.Unread, Shared.shared.uid, Child.Unread)
        ref?.observe(.value) { [weak delegate = delegate] (data) in
            delegate?.setUnread(data.value as? Int)
        }
    }

    deinit {
        ref?.removeAllObservers()
    }
}

protocol UnreadObserverDelegate: class {
    func setUnread(_ unread: Int?)
}
