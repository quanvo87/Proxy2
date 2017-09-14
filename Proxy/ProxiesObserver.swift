import FirebaseDatabase
import UIKit

class ProxiesObserver: ReferenceObserving {
    private(set) var handle: DatabaseHandle?
    private(set) var proxies = [Proxy]()
    private(set) var ref: DatabaseReference?

    func observe(_ tableView: UITableView) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}
