import FirebaseDatabase

class UnreadCountObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(manager: UnreadCountManaging, uid: String) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            manager?.setUnreadCount(Int(data.childrenCount))
        })
    }

    deinit {
        stopObserving()
    }
}
