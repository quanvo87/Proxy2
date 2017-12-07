import FirebaseDatabase

class SenderNicknameObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(senderId: String, convoKey: String, manager: SenderNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, convoKey, Child.senderNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let nickname = data.value as? String {
                manager?.senderNickname = nickname
            }
        })
    }

    deinit {
        stopObserving()
    }
}
