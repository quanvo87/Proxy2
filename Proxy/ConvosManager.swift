class ConvosManager: ConvosManaging {
    let observer = ConvosObserver()
    weak var reloader: ViewReloading?
    var convos = [Convo]() { didSet { reloader?.reload() } }

    func load(convosOwner owner: String, reloader: ViewReloading?) {
        self.reloader = reloader
        observer.observe(convosOwner: owner, manager: self)
    }
}
