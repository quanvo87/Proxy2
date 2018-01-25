import FirebaseDatabase

protocol ConvoObserving: ReferenceObserving {
    func load(convoKey: String, convoSenderId: String, manager: ConvoManaging?)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()

    func load(convoKey: String, convoSenderId: String, manager: ConvoManaging?) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.convos, convoSenderId, convoKey)
        handle = ref?.observe(.value) { [weak self, weak manager] (data) in
            if let convo = Convo(data) {
                manager?.convo = convo
            } else {
                self?.database.getConvo(key: convoKey, ownerId: convoSenderId) { (result) in
                    switch result {
                    case .success(let convo):
                        manager?.convo = convo
                    case .failure:
                        manager?.convo = nil
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
