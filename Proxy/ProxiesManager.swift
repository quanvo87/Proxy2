class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    weak var reloader: ViewReloading?
    var proxies = [Proxy]() { didSet { reloader?.reload() } }

    func load(_ reloader: ViewReloading) {
        self.reloader = reloader
        observer.observe(self)
    }
}
