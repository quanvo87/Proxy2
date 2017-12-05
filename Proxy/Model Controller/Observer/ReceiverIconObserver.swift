import FirebaseDatabase

class ReceiverIconObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(receiverIconManager: ReceiverIconManaging, receiverOwnerId: String, receiverProxyKey: String) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, receiverOwnerId, receiverProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak receiverIconManager = receiverIconManager] (data) in
            if let icon = data.value as? String {
                receiverIconManager?.receiverIcon = icon
            }
        })
    }

    deinit {
        stopObserving()
    }
}
