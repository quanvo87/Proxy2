import FirebaseDatabase

class UnreadCountObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    init() {}

    func observe(_ delegate: UnreadObserverDelegate) {
        ref = DB.makeReference(Child.unreadCount, Shared.shared.uid, Child.unreadCount)
        handle = ref?.observe(.value) { [weak delegate = delegate] (data) in
            delegate?.setUnreadCount(to: data.value as? Int)
        }
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

protocol UnreadObserverDelegate: class {
    func setUnreadCount(to unreadCount: Int?)
}
