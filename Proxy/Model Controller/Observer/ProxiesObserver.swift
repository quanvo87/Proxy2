import FirebaseDatabase

class ProxiesObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxiesManager: ProxiesManaging, uid: String) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak proxiesManager = proxiesManager] (data) in
            proxiesManager?.proxies = data.toProxiesArray().reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
