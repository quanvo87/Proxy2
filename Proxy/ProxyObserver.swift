import FirebaseDatabase
import UIKit

class ProxyObserver: ReferenceObserving {
    private var proxies = NSCache<NSString, AnyObject>()
    private(set) var handle: DatabaseHandle?
    private(set) var ref: DatabaseReference?

    func getProxy(forKey key: String) -> Proxy? {
        return proxies.object(forKey: key as NSString) as? Proxy
    }

    func observe(proxy: Proxy, tableView: UITableView) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            guard let proxy = Proxy(data) else { return }
            self?.proxies.setObject(proxy as AnyObject, forKey: proxy.key as NSString)
            tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}
