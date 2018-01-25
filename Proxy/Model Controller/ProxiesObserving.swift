import FirebaseDatabase

protocol ProxiesObserving: ReferenceObserving {
    func load(proxiesOwnerId: String, proxiesManager: ProxiesManaging)
}

class ProxiesObserver: ProxiesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func load(proxiesOwnerId: String, proxiesManager: ProxiesManaging) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.proxies, proxiesOwnerId)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak proxiesManager] (data) in
            proxiesManager?.proxies = data.toProxiesArray.reversed()
        }
    }

    deinit {
        stopObserving()
    }
}
