import FirebaseDatabase

class ConvoObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(convoOwnerId: String, convoKey: String, manager: ConvoManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convoOwnerId, convoKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            if let convo = Convo(data) {
                manager?.convo = convo
            }
        })
    }

    deinit {
        stopObserving()
    }
}
