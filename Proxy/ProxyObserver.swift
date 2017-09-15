import FirebaseDatabase
import UIKit

class ProxyObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ProxyObserving?
    private(set) var handle: DatabaseHandle?

    init(proxy: Proxy, controller: ProxyObserving) {
        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        self.controller = controller
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let proxy = Proxy(data) else { return }
            self?.controller?.proxy = proxy
            self?.controller?.tableView.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ProxyObserving: class, TableViewOwning {
    var proxy: Proxy? { get set }
}
