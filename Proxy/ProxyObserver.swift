import FirebaseDatabase
import UIKit

class ProxyObserver: ReferenceObserving, TableViewMapTableHandling {
    private let proxies = NSCache<NSString, AnyObject>()

    private(set) var handle: DatabaseHandle?
    private(set) var ref: DatabaseReference?
    private(set) var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    func getProxy(withKey key: String) -> Proxy? {
        return proxies.object(forKey: key as NSString) as? Proxy
    }

    func observe(_ proxy: Proxy) {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }

        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let proxy = Proxy(data) else { return }
            self?.proxies.setObject(proxy as AnyObject, forKey: proxy.key as NSString)
            self?.reloadTableViews()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
