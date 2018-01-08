import FirebaseDatabase

class ConvoObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, key: String, manager: ConvoManaging, closer: Closing) {
        stopObserving()
        ref = DB.makeReference(Child.convos, uid, key)
        handle = ref?.observe(.value) { [weak manager, weak closer] (data) in
            guard let convo = Convo(data) else {
                DB.checkKeyExists(Child.convos, uid, key) { (exists) in
                    if !exists {
                        closer?.shouldClose = true
                    }
                }
                return
            }
            manager?.convo = convo
        }
    }

    deinit {
        stopObserving()
    }
}
