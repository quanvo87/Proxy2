import FirebaseDatabase

class ProxyObserver: ReferenceObserving, TableViewMapTableHandling {
    private(set) var handle: DatabaseHandle?
    private(set) var proxies = NSCache<NSString, AnyObject>()
    private(set) var ref: DatabaseReference?
    private(set) var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    func observe(_ proxy: Proxy) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let proxy = Proxy(data) else { return }
            self?.proxies.setObject(proxy as AnyObject, forKey: proxy.key as NSString)
            self?.reloadTableViews()
        })
    }

    deinit {
        stopObserving()
    }
}
