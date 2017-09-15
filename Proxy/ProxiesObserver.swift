import FirebaseDatabase
import UIKit

class ProxiesObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ProxiesObserving?
    private(set) var handle: DatabaseHandle?

    init(_ controller: ProxiesObserving) {
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        self.controller = controller
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.controller?.proxies = data.toProxiesArray().reversed()
            self?.controller?.tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ProxiesObserving: class, TableViewOwning {
    var proxies: [Proxy] { get set }
}
