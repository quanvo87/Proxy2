import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(ownerId: String, proxyKey: String, manager: ProxyManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, proxyKey)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            guard let proxy = Proxy(data) else {
                return
            }
            manager?.proxy = proxy
        })
    }

    deinit {
        stopObserving()
    }
}
