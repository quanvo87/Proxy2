import FirebaseDatabase

class UnreadCountObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(uid: String, unreadCountManager: UnreadCountManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.value, with: { [weak unreadCountManager = unreadCountManager] (data) in
            unreadCountManager?.unreadCount = Int(data.childrenCount)
        })
    }

    deinit {
        stopObserving()
    }
}
