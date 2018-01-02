import FirebaseDatabase

class ProxiesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ProxiesManaging?

    func observe(uid: String, manager: ProxiesManaging) {
        ref = DB.makeReference(Child.proxies, uid)
        self.manager = manager
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.manager?.proxies = data.asProxiesArray.reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
