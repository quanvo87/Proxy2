import FirebaseDatabase
import UIKit

protocol ProxyManaging: ReferenceObserving {
    var proxy: Proxy? { get }
}

class ProxyManager: ProxyManaging {
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private (set) var proxy: Proxy?

    init(closer: Closing, key: String, tableView: UITableView, uid: String) {
        ref = DB.makeReference(Child.proxies, uid, key)
        handle = ref?.observe(.value) { [weak self, weak tableView] (data) in
            guard let proxy = Proxy(data) else {
                DB.getProxy(uid: uid, key: key) { [weak closer] (proxy) in
                    if proxy == nil {
                        closer?.shouldClose = true
                    }
                }
                return
            }
            self?.proxy = proxy
            tableView?.reloadData()
        }
    }

    deinit {
        stopObserving()
    }
}
