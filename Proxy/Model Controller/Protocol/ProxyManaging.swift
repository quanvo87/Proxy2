import FirebaseDatabase
import UIKit

protocol ProxyManaging: ReferenceObserving {
    var proxy: Proxy? { get }
}

class ProxyManager: ProxyManaging {
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private (set) var proxy: Proxy?

    init(uid: String, key: String, tableView: UITableView, closer: Closing) {
        ref = DB.makeReference(Child.proxies, uid, key)
        handle = ref?.observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard let proxy = Proxy(data) else {
                DB.checkKeyExists(Child.proxies, uid, key) { (exists) in
                    if !exists {
                        closer.shouldClose = true
                    }
                }
                return
            }
            _self.proxy = proxy
            tableView.reloadData()
        }
    }

    deinit {
        stopObserving()
    }
}
