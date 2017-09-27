protocol ConvosManaging: class {
    var convos: [Convo] { get set }
}

class ConvosManager: NSObject, ConvosManaging {
    var observer: ConvosObserver?
    weak var reloader: TableViewReloading?
    var convos = [Convo]() {
        didSet {
            reloader?.reloadTableView()
        }
    }

    init(convosOwner owner: String, delegate: TableViewReloading?) {
        super.init()
        self.reloader = delegate
        observer = ConvosObserver(convosOwner: owner, manager: self)
    }
}
