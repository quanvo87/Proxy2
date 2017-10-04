class ProxyManager: ProxyManaging {
    let observer = ProxyObserver()
    weak var reloader: TableViewReloading?
    var proxy: Proxy? { didSet { reloader?.reloadTableView() } }

    func load(proxy: Proxy, reloader: TableViewReloading) {
        self.reloader = reloader
        observer.observe(manager: self, proxy: proxy)
    }
}
