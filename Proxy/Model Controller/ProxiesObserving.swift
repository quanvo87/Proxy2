import FirebaseDatabase
import FirebaseHelper

protocol ProxiesObserving: ReferenceObserving {
    func observe(proxiesOwnerId: String, callback: @escaping ([Proxy]) -> Void)
}

class ProxiesObserver: ProxiesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxiesOwnerId: String, callback: @escaping ([Proxy]) -> Void) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.proxies, proxiesOwnerId)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value) { data in
            callback(data.toProxiesArray.reversed())
        }
    }

    deinit {
        stopObserving()
    }
}
