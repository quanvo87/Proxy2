import FirebaseDatabase

class ProxiesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: ProxiesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            manager?.proxies = data.toProxiesArray().reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
