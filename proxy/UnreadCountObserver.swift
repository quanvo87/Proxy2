import FirebaseDatabase

class UnreadCountObserver {
    private var ref = DB.makeReference(Child.unreadCount, Shared.shared.uid, Child.unreadCount)

    init() {}

    func observeUnreadCount(_ delegate: UnreadObserverDelegate) {
        ref?.observe(.value) { (data) in
            delegate.setUnreadCount(to: data.value as? Int)
        }
    }

    deinit {
        ref?.removeAllObservers()
    }
}

protocol UnreadObserverDelegate: class {
    func setUnreadCount(to unreadCount: Int?)
}
