import FirebaseDatabase

class ConvoObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, key: String, manager: ConvoManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, uid, key)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            guard let convo = Convo(data) else {
                return
            }
            manager?.convo = convo
        })
    }

    deinit {
        stopObserving()
    }
}
