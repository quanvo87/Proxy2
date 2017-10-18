import FirebaseDatabase

class SenderIconObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderOwnerId: String, senderProxyKey: String, manager: SenderIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, senderOwnerId, senderProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let icon = data.value as? String else { return }
            manager?.senderIcon = icon
        })
    }

    deinit {
        stopObserving()
    }
}
