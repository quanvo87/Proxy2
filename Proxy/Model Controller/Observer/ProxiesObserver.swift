import FirebaseDatabase

class ProxiesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: ProxiesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak manager] (data) in
            manager?.proxies = data.toProxiesArray(uid: uid).reversed()
        }
    }

    deinit {
        stopObserving()
    }
}
