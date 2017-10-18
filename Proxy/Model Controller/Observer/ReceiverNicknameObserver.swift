import FirebaseDatabase

class ReceiverNicknameObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderId: String, key: String, manager: ReceiverNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, key, Child.receiverNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let nickname = data.value as? String else { return }
            manager?.receiverNickname = nickname
        })
    }

    deinit {
        stopObserving()
    }
}
