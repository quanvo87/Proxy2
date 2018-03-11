import FirebaseDatabase
import WQNetworkActivityIndicator

protocol ProxiesObserving: ReferenceObserving {
    func observe(proxiesOwnerId: String, completion: @escaping ([Proxy]) -> Void)
}

class ProxiesObserver: ProxiesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private var firstCallback = true

    func observe(proxiesOwnerId: String, completion: @escaping ([Proxy]) -> Void) {
        stopObserving()
        firstCallback = true
        ref = try? Shared.firebaseHelper.makeReference(Child.proxies, proxiesOwnerId)
        WQNetworkActivityIndicator.shared.show()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { [weak self] data in
            if let firstCallback = self?.firstCallback, firstCallback {
                self?.firstCallback = false
                WQNetworkActivityIndicator.shared.hide()
            }
            completion(data.asProxiesArray.reversed())
        }
    }

    deinit {
        stopObserving()
    }
}
