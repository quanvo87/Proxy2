protocol ConvosManaging: class {
    var convos: [Convo] { get set }
}

class ConvosManager: ConvosManaging {
    let observer = ConvosObserver()
    weak var reloader: TableViewReloading?
    var convos = [Convo]() {
        didSet {
            reloader?.reloadTableView()
        }
    }

    func load(convosOwner owner: String, reloader: TableViewReloading?) {
        self.reloader = reloader
        observer.observe(convosOwner: owner, manager: self)
    }
}
