import FirebaseDatabase

protocol ProxiesObserving: ReferenceObserving {
    func load(manager: ProxiesManaging?, uid: String)
}

class ProxiesObserver: ProxiesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func load(manager: ProxiesManaging?, uid: String) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.proxies, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak manager] (data) in
            manager?.proxies = data.toProxiesArray(uid: uid).reversed()
        }
    }

    deinit {
        stopObserving()
    }
}
