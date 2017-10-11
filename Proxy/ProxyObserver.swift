import FirebaseDatabase
import UIKit

class ProxyObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(ownerId: String, key: String, manager: ProxyManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, ownerId, key)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let proxy = Proxy(data) else { return }
            manager?.proxy = proxy
        })
    }

    deinit {
        stopObserving()
    }
}
