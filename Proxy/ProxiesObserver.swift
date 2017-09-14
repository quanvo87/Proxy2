import FirebaseDatabase
import UIKit

class ProxiesObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private(set) var handle: DatabaseHandle?
    private(set) var proxies = [Proxy]()
    private weak var tableView: UITableView?

    init(_ tableView: UITableView) {
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        self.tableView = tableView
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            self?.tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}
