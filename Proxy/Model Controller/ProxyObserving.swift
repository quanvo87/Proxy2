import FirebaseDatabase
import FirebaseHelper
import WQNetworkActivityIndicator

protocol ProxyObsering: ReferenceObserving {
    func observe(proxyKey: String, proxyOwnerId: String, completion: @escaping (Proxy?) -> Void)
}

class ProxyObserver: ProxyObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()
    private var firstCallback = true

    func observe(proxyKey: String, proxyOwnerId: String, completion: @escaping (Proxy?) -> Void) {
        stopObserving()
        firstCallback = true
        ref = try? FirebaseHelper.main.makeReference(Child.proxies, proxyOwnerId, proxyKey)
        WQNetworkActivityIndicator.shared.show()
        handle = ref?.observe(.value) { [weak self] data in
            if let firstCallback = self?.firstCallback, firstCallback {
                self?.firstCallback = false
                WQNetworkActivityIndicator.shared.hide()
            }
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
