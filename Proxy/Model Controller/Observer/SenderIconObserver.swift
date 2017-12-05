import FirebaseDatabase

class SenderIconObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderIconManager: SenderIconManaging, senderOwnerId: String, senderProxyKey: String) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, senderOwnerId, senderProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak senderIconManager = senderIconManager] (data) in
            if let icon = data.value as? String {
                senderIconManager?.senderIcon = icon
            }
        })
    }

    deinit {
        stopObserving()
    }
}
