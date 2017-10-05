class ProxyManager: ProxyManaging {
    let observer = ProxyObserver()
    weak var reloader: ViewReloading?
    var proxy: Proxy? { didSet { reloader?.reload() } }

    func load(proxy: Proxy, reloader: ViewReloading) {
        self.reloader = reloader
        observer.observe(manager: self, proxy: proxy)
    }
}
