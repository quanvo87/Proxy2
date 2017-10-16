import FirebaseDatabase

class MessagesSentObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(uid: String, manager: MessagesSentManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesSent.rawValue)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let count = data.value as? UInt {
                manager?.messagesSentCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
