import FirebaseDatabase

class ReceiverIconObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(convo: Convo, manager: ReceiverIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let icon = data.value as? String else { return }
            manager?.receiverIcon = icon
        })
    }

    deinit {
        stopObserving()
    }
}
