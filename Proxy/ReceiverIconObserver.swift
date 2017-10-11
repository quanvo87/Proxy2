import FirebaseDatabase

class ReceiverIconObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(ownerId: String, proxyKey: String, manager: ReceiverIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, proxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let icon = data.value as? String else { return }
            manager?.receiverIcon = icon
        })
    }

    deinit {
        stopObserving()
    }
}
