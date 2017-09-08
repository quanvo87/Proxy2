import FirebaseDatabase
import UIKit

class ProxiesObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    private(set) var proxies = [Proxy]()

    init() {}

    func observe(_ tableView: UITableView) {
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            tableView?.visibleCells.incrementTags()
            tableView?.reloadData()
        })
    }

    func stopObserving() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
