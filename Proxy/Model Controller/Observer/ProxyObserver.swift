import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(ownerId: String, proxyKey: String, manager: ProxyManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, proxyKey)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let proxy = Proxy(data) {
                manager?.proxy = proxy
            }
        })
    }

    deinit {
        stopObserving()
    }
}
