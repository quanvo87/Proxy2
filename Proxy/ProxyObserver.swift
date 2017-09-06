import FirebaseDatabase

class ProxyObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private var _proxy = Proxy()

    var proxy: Proxy {
        return _proxy
    }

    init() {}

    func observe(_ proxy: Proxy, tableView: UITableView) {
        ref = DB.makeReference(Child.Proxies, proxy.ownerId, proxy.key)
        handle = ref?.observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            guard let proxy = Proxy(data) else {
                return
            }
            self?._proxy = proxy
            tableView?.reloadData()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
