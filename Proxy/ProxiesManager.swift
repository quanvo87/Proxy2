class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    weak var reloader: TableViewReloading?
    var proxies = [Proxy]() { didSet { reloader?.reloadTableView() } }

    func load(_ reloader: TableViewReloading) {
        self.reloader = reloader
        observer.observe(self)
    }
}
