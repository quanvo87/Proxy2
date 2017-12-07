import FirebaseDatabase

class SenderNicknameObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderNicknameManager: SenderNicknameManaging, convoKey: String, senderId: String) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, convoKey, Child.senderNickname)
        handle = ref?.observe(.value, with: { [weak senderNicknameManager = senderNicknameManager] (data) in
            if let nickname = data.value as? String {
                senderNicknameManager?.senderNickname = nickname
            }
        })
    }

    deinit {
        stopObserving()
    }
}
