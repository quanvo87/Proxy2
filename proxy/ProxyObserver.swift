import FirebaseDatabase

class ProxyObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private var proxy = Proxy()

    init() {}

    func getProxy() -> Proxy {
        return proxy
    }

    func observe(_ proxy: Proxy, tableView: UITableView) {
        ref = DB.makeReference(Child.Proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            guard let proxy = Proxy(data.value as AnyObject) else {
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
