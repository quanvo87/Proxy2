import FirebaseDatabase

class SenderNicknameObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderId: String, key: String, manager: SenderNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, senderId, key, Child.senderNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let nickname = data.value as? String else { return }
            manager?.senderNickname = nickname
        })
    }

    deinit {
        stopObserving()
    }
}
