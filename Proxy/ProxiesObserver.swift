import FirebaseDatabase
import UIKit

class ProxiesObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    private(set) var proxies = [Proxy]()

    init() {}

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

extension ProxiesObserver {
    func addTableView(_ tableView: UITableView, forKey key: Int) {
        tableViews.setObject(tableView, forKey: key as AnyObject)
    }

    func removeTableView(forKey key: Int) {
        tableViews.removeObject(forKey: key as AnyObject)
    }
}

extension ProxiesObserver {
    func observe() {
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            for tableView in self?.tableViews.objectEnumerator() ?? NSEnumerator() {
                if let tableView = tableView as? UITableView {
                    tableView.reloadData()
                }
            }
        })
    }

    func stopObserving() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
