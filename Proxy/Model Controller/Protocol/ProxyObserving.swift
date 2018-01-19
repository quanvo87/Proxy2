import FirebaseDatabase

protocol ProxyObsering: ReferenceObserving {
    func load(proxyKey: String, uid: String, manager: ProxyManaging)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func load(proxyKey: String, uid: String, manager: ProxyManaging) {
        ref = DB.makeReference(Child.proxies, uid, proxyKey)
        handle = ref?.observe(.value) { [weak manager] (data) in
            guard let proxy = Proxy(data) else {
                DB.getProxy(uid: uid, key: proxyKey) { (proxy) in
                    manager?.proxy = proxy
                }
                return
            }
            manager?.proxy = proxy
        }
    }

    deinit {
        stopObserving()
    }
}
