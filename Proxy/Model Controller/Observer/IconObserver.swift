import FirebaseDatabase
import UIKit

class IconObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(proxyOwner: String, proxyKey: String, manager: IconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, proxyOwner, proxyKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            guard let proxy = Proxy(data) else {
                return
            }
            UIImage.make(name: proxy.icon) { (image) in
                manager?.icons[proxy.key] = image
            }
        })
    }

    deinit {
        stopObserving()
    }
}
