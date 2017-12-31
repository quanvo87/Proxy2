import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(ownerId: String, proxyKey: String, manager: ProxyManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, proxyKey)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            if let proxy = Proxy(data: data, ref: DB.makeReference(Child.proxies, ownerId)) {
                manager?.proxy = proxy
            } else {
                self.ref?.removeValue()
            }
        })
    }

    deinit {
        stopObserving()
    }
}
