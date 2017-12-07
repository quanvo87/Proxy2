import FirebaseDatabase

class ReceiverNicknameObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(senderId: String, convoKey: String, manager: ReceiverNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, convoKey, Child.receiverNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let nickname = data.value as? String {
                manager?.receiverNickname = nickname
            }
        })
    }

    deinit {
        stopObserving()
    }
}
