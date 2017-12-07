import FirebaseDatabase

class ReceiverNicknameObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(receiverNicknameManager: ReceiverNicknameManaging, convoKey: String, senderId: String) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, convoKey, Child.receiverNickname)
        handle = ref?.observe(.value, with: { [weak receiverNicknameManager = receiverNicknameManager] (data) in
            if let nickname = data.value as? String {
                receiverNicknameManager?.receiverNickname = nickname
            }
        })
    }

    deinit {
        stopObserving()
    }
}
