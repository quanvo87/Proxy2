import FirebaseDatabase
import UIKit

class ProxyObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(manager: ProxyManaging, proxy: Proxy) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let proxy = Proxy(data) else { return }
            manager?.proxy = proxy
        })
    }

    deinit {
        stopObserving()
    }
}
