import FirebaseDatabase

class MessagesSentObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: MessagesSentCountManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesSent.rawValue)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            manager?.messagesSentCount = data.asNumberLabel
        })
    }

    deinit {
        stopObserving()
    }
}
