import FirebaseDatabase

class MessagesReceivedObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(messagesReceivedCountManager: MessagesReceivedCountManaging, uid: String) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesReceived.rawValue)
        handle = ref?.observe(.value, with: { [weak messagesReceivedCountManager = messagesReceivedCountManager] (data) in
            if let count = data.value as? UInt {
                messagesReceivedCountManager?.messagesReceivedCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
