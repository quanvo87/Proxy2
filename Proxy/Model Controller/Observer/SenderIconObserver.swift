import FirebaseDatabase

class SenderIconObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(senderOwnerId: String, senderProxyKey: String, manager: SenderIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, senderOwnerId, senderProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let icon = data.value as? String {
                manager?.senderIcon = icon
            }
        })
    }

    deinit {
        stopObserving()
    }
}
