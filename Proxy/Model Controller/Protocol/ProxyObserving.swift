import FirebaseDatabase

protocol ProxyObsering: ReferenceObserving {
    func load(proxyKey: String, uid: String, manager: ProxyManaging?)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = FirebaseDatabase()

    func load(proxyKey: String, uid: String, manager: ProxyManaging?) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.proxies, uid, proxyKey)
        handle = ref?.observe(.value) { [weak self, weak manager] (data) in
            if let proxy = Proxy(data) {
                manager?.proxy = proxy
            } else {
                self?.database.getProxy(key: proxyKey, ownerId: uid) { (result) in
                    switch result {
                    case .success(let proxy):
                        manager?.proxy = proxy
                    default:
                        break
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
