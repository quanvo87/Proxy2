import FirebaseDatabase

class UnreadCountObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(uid: String, manager: UnreadCountManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            manager?.unreadCount = Int(data.childrenCount)
        })
    }

    deinit {
        stopObserving()
    }
}
