import FirebaseDatabase

protocol ProxiesObserving: ReferenceObserving {
    func observe(proxiesOwnerId: String, completion: @escaping ([Proxy]) -> Void)
}

class ProxiesObserver: ProxiesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxiesOwnerId: String, completion: @escaping ([Proxy]) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.proxies, proxiesOwnerId)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { data in
            completion(data.asProxiesArray.reversed())
        }
    }

    deinit {
        stopObserving()
    }
}
