protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
}

class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    weak var reloader: TableViewReloading?
    var proxies = [Proxy]() {
        didSet {
            reloader?.reloadTableView()
        }
    }

    func load(_ reloader: TableViewReloading) {
        self.reloader = reloader
        observer.observe(self)
    }
}
