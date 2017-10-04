class ProxiesInteractedWithManager: ProxiesInteractedWithManaging {
    let observer = ProxiesInteractedWithObserver()
    weak var reloader: TableViewReloading?
    var proxiesInteractedWithCount = "-" { didSet { reloader?.reloadTableView() } }

    func load(reloader: TableViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
