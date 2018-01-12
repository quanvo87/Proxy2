import FirebaseDatabase
import UIKit

class IconObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private let proxyKey: String
    private let uid: String
    private weak var manager: IconManaging?

    init(proxyKey: String, uid: String, manager: IconManaging) {
        self.proxyKey = proxyKey
        self.uid = uid
        self.manager = manager
        ref = DB.makeReference(Child.proxies, uid, proxyKey, Child.icon)
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value) { [weak self] (data) in
            guard let strong = self else {
                return
            }
            guard let icon = data.value as? String else {
                return
            }
            strong.manager?.icons[strong.proxyKey] = UIImage(named: icon)
        }
    }

    deinit {
        stopObserving()
    }
}
