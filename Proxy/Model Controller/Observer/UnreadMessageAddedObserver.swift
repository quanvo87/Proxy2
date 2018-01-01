import FirebaseDatabase

class UnreadMessageAddedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: UnreadMessagesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.childAdded, with: { [weak manager] (data) in
            guard let message = Message(data) else {
                self.ref?.child(data.key).removeValue()
                return
            }
            if manager?.convosPresentIn[message.parentConvoKey] != nil {
                DB.read(message) { _ in }
            } else {
                manager?.unreadMessages.append(message)
            }
        })
    }

    deinit {
        stopObserving()
    }
}
