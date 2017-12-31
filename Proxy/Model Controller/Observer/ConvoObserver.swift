import FirebaseDatabase

class ConvoObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(convoOwnerId: String, convoKey: String, manager: ConvoManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convoOwnerId, convoKey)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            if let convo = Convo(data: data, ref: DB.makeReference(Child.convos, convoOwnerId)) {
                manager?.convo = convo
            } else {
                self.ref?.removeValue()
            }
        })
    }

    deinit {
        stopObserving()
    }
}
