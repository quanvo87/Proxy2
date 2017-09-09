import FirebaseDatabase
import UIKit

class ProxyObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private(set) var proxy: Proxy?


    private var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    private let cache = NSCache<NSString, AnyObject>()

    init() {}



    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

extension ProxyObserver {
    func addTableView(_ tableView: UITableView, forKey key: Int) {
        tableViews.setObject(tableView, forKey: key as AnyObject)
    }

    func removeTableView(forKey key: Int) {
        tableViews.removeObject(forKey: key as AnyObject)
    }
}

extension ProxyObserver {
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
}
