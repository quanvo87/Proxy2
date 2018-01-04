import FirebaseDatabase
import UIKit

class IconObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, proxyKey: String, manager: IconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, uid, proxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager] (data) in
            guard let icon = data.value as? String else {
                return
            }
            UIImage.make(name: icon) { (image) in
                manager?.icons[proxyKey] = image
            }
        })
    }

    deinit {
        stopObserving()
    }
}
