import FirebaseDatabase

class MessagesSentObserver: ReferenceObserving {
    var ref: DatabaseReference?
    var handle: DatabaseHandle?

    func observe(manager: MessagesSentManaging, uid: String) {
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
