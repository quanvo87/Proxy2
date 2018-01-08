import FirebaseDatabase

class UnreadMessageRemovedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: UnreadMessagesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.childRemoved) { [weak manager] (data) in
            guard
                let message = Message(data),
                let index = manager?.unreadMessages.index(of: message) else {
                    return
            }
            manager?.unreadMessages.remove(at: index)
        }
    }

    deinit {
        stopObserving()
    }
}
