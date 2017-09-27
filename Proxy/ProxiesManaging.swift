protocol ProxiesManaging: class {
    var proxies: [Proxy] { get set }
}

class ProxiesManager: ProxiesManaging {
    let observer = ProxiesObserver()
    weak var reloader: TableViewReloader?
    var proxies = [Proxy]() {
        didSet {
            reloader?.reloadTableView()
        }
    }

    func load(_ reloader: TableViewReloader) {
        self.reloader = reloader
        observer.observe(self)
    }
}
