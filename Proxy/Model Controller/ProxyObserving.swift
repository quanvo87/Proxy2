import FirebaseDatabase
import FirebaseHelper

protocol ProxyObsering: ReferenceObserving {
    func observe(proxyKey: String, proxyOwnerId: String, proxyManager: ProxyManaging)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()

    func observe(proxyKey: String, proxyOwnerId: String, proxyManager: ProxyManaging) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.proxies, proxyOwnerId, proxyKey)
        handle = ref?.observe(.value) { [weak self, weak proxyManager] (data) in
            if let proxy = try? Proxy(data) {
                proxyManager?.proxy = proxy
            } else {
                self?.database.getProxy(key: proxyKey, ownerId: proxyOwnerId) { (result) in
                    switch result {
                    case .success(let proxy):
                        proxyManager?.proxy = proxy
                    case .failure:
                        proxyManager?.proxy = nil
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
