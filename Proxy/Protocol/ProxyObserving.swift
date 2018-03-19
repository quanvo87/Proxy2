import FirebaseDatabase

protocol ProxyObsering: ReferenceObserving {
    func observe(proxyKey: String, proxyOwnerId: String, completion: @escaping (Proxy?) -> Void)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()

    func observe(proxyKey: String, proxyOwnerId: String, completion: @escaping (Proxy?) -> Void) {
        stopObserving()
        ref = try? Constant.firebaseHelper.makeReference(Child.proxies, proxyOwnerId, proxyKey)
        handle = ref?.observe(.value) { [weak self] data in
            do {
                completion(try Proxy(data))
            } catch {
                self?.database.getProxy(proxyKey: proxyKey, ownerId: proxyOwnerId) { result in
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
