import FirebaseDatabase

class ReceiverNicknameObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(convo: Convo, manager: ReceiverNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.receiverNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let nickname = data.value as? String else { return }
            manager?.receiverNickname = nickname
        })
    }

    deinit {
        stopObserving()
    }
}
