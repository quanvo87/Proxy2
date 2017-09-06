import FirebaseDatabase

class UnreadCountObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    init() {}

    func observe(uid: String = Shared.shared.uid, delegate: UnreadCountObserverDelegate) {
        ref = DB.makeReference(Child.UserInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.value, with: { [weak delegate = delegate] (data) in
            delegate?.setUnreadCount(to: Int(data.childrenCount))
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

protocol UnreadCountObserverDelegate: class {
    func setUnreadCount(to unreadCount: Int?)
}
