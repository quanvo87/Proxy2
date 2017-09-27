import FirebaseDatabase
import UIKit

class ProxiesObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(_ manager: ProxiesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            manager?.proxies = data.toProxiesArray().reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
