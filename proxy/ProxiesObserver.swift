import FirebaseDatabase

class ProxiesObserver {
    private var ref = DB.makeReference(Child.Proxies, Shared.shared.uid)
    private var proxies = [Proxy]()

    init() {}

    func getProxies() -> [Proxy] {
        return proxies
    }

    func observeProxies(_ tableView: UITableView) {
        ref?.queryOrdered(byChild: Child.Timestamp).observe(.value, with: { [weak self] (data) in
            self?.proxies = data.toProxies().reversed()
            tableView.visibleCells.incrementTags()
            tableView.reloadData()
        })
    }

    deinit {
        ref?.removeAllObservers()
    }
}
