import FirebaseDatabase

typealias NicknamesManaging = ReceiverNicknameManaging & SenderNicknameManaging

class ReceiverNicknameObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var manager: ReceiverNicknameManaging?
    private(set) var handle: DatabaseHandle?

    init(convo: Convo, manager: ReceiverNicknameManaging) {
        self.manager = manager
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.receiverNickname)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let nickname = data.value as? String else { return }
            self?.manager?.setReceiverNickname(nickname)
        })
    }

    deinit {
        stopObserving()
    }
}

class SenderNicknameObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var manager: SenderNicknameManaging?
    private(set) var handle: DatabaseHandle?

    init(convo: Convo, manager: SenderNicknameManaging) {
        self.manager = manager
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.senderNickname)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let nickname = data.value as? String else { return }
            self?.manager?.setSenderNickname(nickname)
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ReceiverNicknameManaging: class {
    func setReceiverNickname(_ nickname: String)
}

protocol SenderNicknameManaging: class {
    func setSenderNickname(_ nickname: String)
}
