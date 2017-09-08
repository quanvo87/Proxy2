import FirebaseDatabase
import UIKit

class ProxyObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private(set) var proxy = Proxy()

    init() {}

    func observe(_ proxy: Proxy, tableView: UITableView) {
        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            guard let proxy = Proxy(data) else {
                return
            }
            self?.proxy = proxy
            tableView?.reloadData()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
