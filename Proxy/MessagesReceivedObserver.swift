import FirebaseDatabase

class MessagesReceivedObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?
    weak var manager: MessagesReceivedManaging?

    func observe(manager: MessagesReceivedManaging, uid: String) {
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
