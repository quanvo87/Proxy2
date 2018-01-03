import FirebaseDatabase

class MessagesReceivedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: MessagesReceivedManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesReceived.rawValue)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            manager?.messagesReceivedCount = data.asNumberLabel
        })
    }

    deinit {
        stopObserving()
    }
}
