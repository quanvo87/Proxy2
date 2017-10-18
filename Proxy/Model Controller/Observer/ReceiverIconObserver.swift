import FirebaseDatabase

class ReceiverIconObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(receiverOwnerId: String, receiverProxyKey: String, manager: ReceiverIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, receiverOwnerId, receiverProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let icon = data.value as? String else { return }
            manager?.receiverIcon = icon
        })
    }

    deinit {
        stopObserving()
    }
}
