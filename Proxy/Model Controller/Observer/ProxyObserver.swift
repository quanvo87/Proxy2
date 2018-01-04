import FirebaseDatabase

class ProxyObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, key: String, manager: ProxyManaging, closer: Closing) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid, key)
        handle = ref?.observe(.value, with: { [weak manager, weak closer] (data) in
            guard let proxy = Proxy(data) else {
                DB.checkKeyExists(Child.proxies, uid, key) { (exists) in
                    if !exists {
                        closer?.shouldClose = true
                    }
                }
                return
            }
            manager?.proxy = proxy
        })
    }

    deinit {
        stopObserving()
    }
}
