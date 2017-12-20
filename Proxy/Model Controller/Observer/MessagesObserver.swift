import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(convoKey: String, manager: MessagesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.messages, convoKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            manager?.messages = data.toMessagesArray().reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
