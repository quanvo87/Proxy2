import FirebaseDatabase

class SenderNicknameObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(convo: Convo, manager: SenderNicknameManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.senderNickname)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let nickname = data.value as? String else { return }
            manager?.senderNickname = nickname
        })
    }

    deinit {
        stopObserving()
    }
}
