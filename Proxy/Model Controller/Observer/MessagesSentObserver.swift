import FirebaseDatabase

class MessagesSentObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(messagesSentCountManager: MessagesSentCountManaging, uid: String) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesSent.rawValue)
        handle = ref?.observe(.value, with: { [weak messagesSentCountManager = messagesSentCountManager] (data) in
            if let count = data.value as? UInt {
                messagesSentCountManager?.messagesSentCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
