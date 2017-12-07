import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxyManager: ProxyManaging, ownerId: String, proxyKey: String) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, proxyKey)
        handle = ref?.observe(.value, with: { [weak proxyManager = proxyManager] (data) in
            if let proxy = Proxy(data) {
                proxyManager?.proxy = proxy
            }
        })
    }

    deinit {
        stopObserving()
    }
}
