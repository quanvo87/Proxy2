import FirebaseDatabase

// todo: change all uid & key to more descriptive name
protocol ConvoObserving: ReferenceObserving {
    func load(convoKey: String, convoSenderId: String, manager: ConvoManaging?)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func load(convoKey: String, convoSenderId: String, manager: ConvoManaging?) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convoSenderId, convoKey)
        handle = ref?.observe(.value) { [weak manager] (data) in
            if let convo = Convo(data) {
                manager?.convo = convo
            } else {
                DB.getConvo(uid: convoSenderId, key: convoKey) { (convo) in
                    manager?.convo = convo
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
