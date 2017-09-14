import FirebaseDatabase

class ProxiesObserver: ReferenceObserving, TableViewsReloading {
    private(set) var handle: DatabaseHandle?
    private(set) var proxies = [Proxy]()
    private(set) var ref: DatabaseReference?
    private(set) var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    func observe() {
        stopObserving()
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            self?.reloadTableViews()
        })
    }

    deinit {
        stopObserving()
    }
}
