class ProxiesInteractedWithManager: ProxiesInteractedWithManaging {
    let observer = ProxiesInteractedWithObserver()
    weak var reloader: ViewReloading?
    var proxiesInteractedWithCount = "-" { didSet { reloader?.reload() } }

    func load(reloader: ViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
