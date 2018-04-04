import FirebaseDatabase

protocol ProxyObsering: ReferenceObserving {
    func observe(proxyOwnerId: String, proxyKey: String, completion: @escaping (Proxy?) -> Void)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxyOwnerId: String, proxyKey: String, completion: @escaping (Proxy?) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.proxies, proxyOwnerId, proxyKey)
        handle = ref?.observe(.value) { data in
            do {
                completion(try Proxy(data))
            } catch {
                Firebase.getProxy(ownerId: proxyOwnerId, proxyKey: proxyKey) { result in
                    switch result {
                    case .success(let proxy):
                        completion(proxy)
                    case .failure:
                        completion(nil)
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
