import FirebaseDatabase

class MessagesReceivedObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(uid: String, manager: MessagesReceivedManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesReceived.rawValue)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let count = data.value as? UInt {
                manager?.messagesReceivedCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
