import FirebaseDatabase

class ReceiverIconObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(receiverOwnerId: String, receiverProxyKey: String, manager: ReceiverIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, receiverOwnerId, receiverProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let icon = data.value as? String {
                manager?.receiverIcon = icon
            }
        })
    }

    deinit {
        stopObserving()
    }
}
