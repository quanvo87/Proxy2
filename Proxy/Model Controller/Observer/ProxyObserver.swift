import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, key: String, manager: ProxyManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid, key)
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
