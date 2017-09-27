import FirebaseDatabase

class UnreadCountObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(user: String = Shared.shared.uid, manager: UnreadCountManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, user, Child.unreadMessages)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            manager?.setUnreadCount(Int(data.childrenCount))
        })
    }

    deinit {
        stopObserving()
    }
}
